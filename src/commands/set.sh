# Handlers register as 'name|description', see core/handlers.sh
MAGE_SET_HANDLERS=()

# Change a setting of the project, by the handler of the given option
function mage_cmd_set() {
  case "$1" in
    "")
      mage_error "Nothing to set, use one of the options below"
      mage_set_help
      exit 1
      ;;
    "help" | "-h" | "--help")
      mage_set_help
      return
      ;;
  esac

  if ! mage_handler_exists "$1" "${MAGE_SET_HANDLERS[@]}"; then
    mage_error "Unknown set option '$1'"
    mage_set_help
    exit 1
  fi

  mage_handler_run set "$@"
}

function mage_set_help() {
  mage_help_header "Set"
  mage_handler_help set "${MAGE_SET_HANDLERS[@]}"
}
