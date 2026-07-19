function mage_ai_git() {
  # The Magento root is a disposable test bed for the packages under
  # package-source, so this repository stays local and never gets a remote.
  # The packages themselves carry their own git repositories and remotes.
  if [ -d .git ]; then
    echo -e "- Git: ${YELLOW}already a repository, skipped${RESET}"
  else
    git init -q
    echo -e "- Git: ${GREEN}initialized (local only, no remote)${RESET}"
  fi

  if [ -f .gitignore ]; then
    echo -e "- Gitignore: ${YELLOW}already exists, skipped${RESET}"
    return
  fi

  cat > .gitignore <<'GITIGNORE'
# Magento runtime and build output
/vendor/
/generated/
/var/
/pub/static/
/pub/media/
/pub/sitemap.xml
/node_modules/

# Local configuration and secrets
/app/etc/env.php
/app/etc/config.php
/auth.json
/.env

# Local packages carry their own git repositories.
# Tracking them here creates embedded repository conflicts.
/package-source/

# Editor and OS noise
.DS_Store
.idea/
.vscode/
*.log
GITIGNORE

  echo -e "- Gitignore: ${GREEN}written${RESET}"
}

function mage_ai_ask_stack() {
  # Magento is the base. Everything beyond it is a layer the project may or may
  # not use, so detect what is already installed and let the answer be changed.
  local detected_frontend="luma"

  if is_hyva_installed; then
    local detected_frontend="hyva"
  fi

  echo -e "\n${BOLD}Code stack${RESET}"
  echo -e "${ITALIC}The detected value is the default, press enter to accept.${RESET}\n"

  read -p "Frontend stack? [luma/hyva/none] (${detected_frontend}): " AI_FRONTEND
  AI_FRONTEND="${AI_FRONTEND:-$detected_frontend}"
}

function mage_ai_write_stack_notes() {
  # Only the layers this project actually uses get documented. A CLAUDE.md that
  # describes a stack the project does not have is worse than no CLAUDE.md.
  case "$AI_FRONTEND" in
    "hyva")
      cat >> CLAUDE.md <<'CLAUDEMD'

### Frontend: Hyvä

* Tailwind, compiled from the theme's `web/tailwind` directory.
* Build with `mage build hyva`. Do not hand edit compiled CSS.
* Alpine.js for interactivity, written CSP safe (no inline expressions that
  violate the policy).
* Luma layout XML and `requirejs` patterns do not apply here.
CLAUDEMD
      ;;
    "luma")
      cat >> CLAUDE.md <<'CLAUDEMD'

### Frontend: Luma

* LESS, compiled by Magento. In developer mode it recompiles on request.
* Layout XML and `requirejs` are the normal extension points.
* Prefer a child theme over editing Luma directly.
CLAUDEMD
      ;;
    *)
      cat >> CLAUDE.md <<'CLAUDEMD'

### Frontend

No storefront theme layer is configured for this project. Ask before assuming
Luma, Hyvä, or any other frontend stack.
CLAUDEMD
      ;;
  esac
}

function mage_ai_context() {
  # CLAUDE.md is read automatically by Claude Code on every session in this
  # directory. It carries the facts an agent cannot infer from the code alone.
  if [ -f CLAUDE.md ]; then
    echo -e "- CLAUDE.md: ${YELLOW}already exists, skipped${RESET}"
    return
  fi

  local name=$(basename "$(pwd)")
  local mode=$($MAGENTO_CLI deploy:mode:show 2>/dev/null | grep -oE '(developer|production|default)' | head -n1)

  if [[ -z "$mode" ]]; then
    local mode="developer"
  fi

  cat > CLAUDE.md <<CLAUDEMD
# ${name}

Magento development instance. It exists to develop and test the packages under
\`package-source/\`. The root itself is disposable.

## Deploy mode

This instance runs in **${mode}** mode (verify with \`bin/magento deploy:mode:show\`).
CLAUDEMD

  if [[ "$mode" == "developer" ]]; then
    cat >> CLAUDE.md <<'CLAUDEMD'

Consequences:

* Static content is generated on demand. Do not run or suggest
  `setup:static-content:deploy` after installing or editing a module.
* Do not run or suggest `cache:flush` / `cache:clean` as routine follow up.
* Only reach for these if something actually fails to render, or if asked.
CLAUDEMD
  fi

  cat >> CLAUDE.md <<'CLAUDEMD'

## Local packages

`package-source/*/*` is a Composer `path` repository (`local-packages`), so packages
there install as **symlinks**. Edits take effect immediately, with no reinstall.

Each package carries its own git repository and its own remote. That is where real
work is committed, and where issues belong.

## Git

The root has a **local only** git repository with no remote, kept for diffing and
undo. Never add a remote here and never push from the root. `package-source/` is
gitignored precisely because those packages are tracked separately.

## Stack
CLAUDEMD

  mage_ai_write_stack_notes

  cat >> CLAUDE.md <<'CLAUDEMD'

## Tooling

* `mage` wraps `bin/magento`. Run `mage help` for the command list.
* `mage watch` runs cache-clean, so cache flushes are rarely needed by hand.
CLAUDEMD

  echo -e "- CLAUDE.md: ${GREEN}written (mode: ${mode}, frontend: ${AI_FRONTEND})${RESET}"
}

function mage_ai_mcp() {
  # magento2-lsp answers questions about the merged, compiled config (real plugin
  # chains, preference winners, template override order) instead of grepping.
  #
  # Note: plain npm here, not $NPM_CLI. Claude Code runs on the host, so the MCP
  # server has to be installed on the host too, even under Warden.
  if ! command -v claude &>/dev/null; then
    echo -e "- MCP: ${YELLOW}claude CLI not found, skipped${RESET}"
    return
  fi

  if claude mcp list 2>/dev/null | grep -q 'magento2-lsp-mcp'; then
    echo -e "- MCP: ${YELLOW}magento2-lsp-mcp already registered, skipped${RESET}"
    return
  fi

  if ! command -v npm &>/dev/null; then
    echo -e "- MCP: ${YELLOW}npm not found, skipped${RESET}"
    return
  fi

  if ! command -v magento2-lsp-mcp &>/dev/null; then
    echo "Installing @mage-os/magento2-lsp..."
    npm install -g @mage-os/magento2-lsp
  fi

  # User scope, so a single registration serves every Magento project. The server
  # finds the project root per call by walking up to app/etc/di.xml.
  claude mcp add -s user magento2-lsp-mcp magento2-lsp-mcp &>/dev/null

  echo -e "- MCP: ${GREEN}magento2-lsp-mcp registered at user scope${RESET}"
}

function mage_ai_packages() {
  # mage install sets this up, but mage ai also has to work on a Magento root
  # that came from somewhere else.
  if $COMPOSER_CLI config repositories.local-packages &>/dev/null; then
    echo -e "- Packages: ${YELLOW}local-packages repository already set, skipped${RESET}"
    return
  fi

  mkdir -p package-source
  $COMPOSER_CLI config repositories.local-packages path "package-source/*/*"

  echo -e "- Packages: ${GREEN}package-source/*/* registered as a path repository${RESET}"
}

function mage_ai_setup() {
  mage_ai_ask_stack

  echo -e "\n${BOLD}Setting up for AI assisted development${RESET}"

  mage_ai_git
  mage_ai_context
  mage_ai_packages
  mage_ai_mcp

  echo -e "\n${GREEN}Ready.${RESET} Open the project with your agent of choice."
}
