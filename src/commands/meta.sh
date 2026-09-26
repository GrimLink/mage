function mage_cmd_version() {
  mage_info "${BOLD}Mage ${GREEN}${MAGE_VERSION}${RESET}, ${ITALIC}See https://github.com/GrimLink/mage for the latest version${RESET}"
}

function mage_help_header() {
  mage_info ""
  mage_info "${BOLD}$1${RESET}"
}

function mage_help_cmd() {
  printf "  %s%-30s%s %s\n" "$GREEN" "$1" "$RESET" "$2"
}

function mage_cmd_help() {
  mage_help_header "General"
  mage_help_cmd "help"                        "Show this help"
  mage_help_cmd "version"                     "Show the mage version"
  mage_help_cmd "self-update"                 "Update mage"

  mage_help_header "Project"
  mage_help_cmd "create [NAME]"               "Create, install and set up a new Magento 2 project"
  mage_help_cmd "  --edition=[EDITION]"       "community (default), enterprise or mage-os"
  mage_help_cmd "  --version=[VERSION]"       "Magento version (default: latest)"
  mage_help_cmd "  --env=[ENV]"               "warden, ddev, valet or local (default: first one installed)"
  mage_help_cmd "  -y, --yes"                 "Use the defaults instead of asking"
  mage_help_cmd "setup [NAME]"                "Reinstall Magento in an existing project"
  mage_help_cmd "nuke"                        "Permanently delete the project (database, environment, files)"
  mage_help_cmd "  --keep-files"              "Keep the project files"

  mage_help_header "Packages"
  mage_help_cmd "add [PKG|GIT_URL|HANDLER]"   "Add to the project, see 'mage add help' for all options"

  mage_help_header "Development"
  mage_help_cmd "clean/purge [OPTION]"        "Clean caches and files, see 'mage clean help' for all options"

  mage_info ""
  mage_info "${ITALIC}Anything else will run ${GREEN}bin/magento${RESET}"
  mage_info "${ITALIC}From a nested folder, mage runs from the Magento root${RESET}"
}

# Replace this script with the latest release, following any symlinks to it
function mage_cmd_self_update() {
  if [[ "$MAGE_VERSION" == "dev" ]]; then
    mage_error "self-update only works for the built mage script"
    exit 1
  fi

  local target="$MAGE_SELF"
  local link

  while [[ -L "$target" ]]; do
    link="$(readlink "$target")"

    if [[ "$link" == /* ]]; then
      target="$link"
    else
      target="$(dirname "$target")/${link}"
    fi
  done

  if ! mage_download_file "$MAGE_UPDATE_URL" "$target"; then
    mage_error "Could not download ${MAGE_UPDATE_URL}"
    exit 1
  fi

  chmod +x "$target"
  "$target" version
}
