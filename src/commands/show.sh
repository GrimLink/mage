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
