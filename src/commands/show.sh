# Handlers register as 'name|description', see core/handlers.sh
MAGE_SHOW_HANDLERS=()

# Show information about the project, by the handler of the given option
function mage_cmd_show() {
  case "$1" in
    "")
      mage_error "Nothing to show, use one of the options below"
      mage_show_help
      exit 1
      ;;
    "help" | "-h" | "--help")
      mage_show_help
      return
      ;;
  esac

  if ! mage_handler_exists "$1" "${MAGE_SHOW_HANDLERS[@]}"; then
    mage_error "Unknown show option '$1'"
    mage_show_help
    exit 1
  fi

  mage_handler_run show "$@"
}

function mage_show_help() {
  mage_help_header "Show"
  mage_handler_help show "${MAGE_SHOW_HANDLERS[@]}"
}

# Echo 'name<tab>source<tab>folder' for every component of the type (MODULE or THEME)
# that a direct dependency registers, followed by those in the given local registration.php
# files, with the label as their source. Like outdated, only the direct dependencies count,
# so the components they pull in, such as those of Magento itself, stay out.
function mage_show_components() {
  local type="$1"
  local label="$2"
  shift 2

  local package
  local file
  local name

  while IFS= read -r package; do
    if [[ ! -d "vendor/${package}" ]]; then
      continue
    fi

    # The trailing slash follows the symlink of a path repository package
    while IFS= read -r file; do
      name="$(mage_component_name "$file" "$type")"
      if [[ -n "$name" ]]; then
        printf '%s\t%s\t%s\n' "$name" "$package" "$(dirname "$file")"
      fi
    done < <(find "vendor/${package}/" -maxdepth 3 -name registration.php -not -path "*/node_modules/*")
  done < <(jq -r '(.require // {}), (."require-dev" // {}) | keys[] | select(contains("/"))' composer.json)

  for file in "$@"; do
    if [[ -f "$file" ]]; then
      name="$(mage_component_name "$file" "$type")"
      if [[ -n "$name" ]]; then
        printf '%s\t%s\t%s\n' "$name" "$label" "$(dirname "$file")"
      fi
    fi
  done
}

# Echo the name a registration.php registers for the type, such as
# Vendor_Module for MODULE or frontend/Vendor/theme for THEME
function mage_component_name() {
  tr '\n' ' ' < "$1" |
    grep -o "ComponentRegistrar::$2,[[:space:]]*['\"][A-Za-z0-9_/-]*['\"]" |
    head -n 1 |
    sed -E "s/.*['\"]([A-Za-z0-9_/-]+)['\"]$/\1/"
}
