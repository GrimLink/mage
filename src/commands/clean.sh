# Handlers register as 'name|description', see core/handlers.sh
MAGE_CLEAN_HANDLERS=()

# Clean a part of the project, or with 'all' the handlers in MAGE_CLEAN_ALL
function mage_cmd_clean() {
  case "$1" in
    "")
      mage_error "Nothing to clean, use one of the options below"
      mage_clean_help
      exit 1
      ;;
    "help" | "-h" | "--help")
      mage_clean_help
      return
      ;;
    "all")
      mage_clean_all
      return
      ;;
  esac

  if ! mage_handler_exists "$1" "${MAGE_CLEAN_HANDLERS[@]}"; then
    mage_error "Unknown clean option '$1'"
    mage_clean_help
    exit 1
  fi

  mage_handler_run clean "$@"
}

function mage_clean_all() {
  local name

  for name in $MAGE_CLEAN_ALL; do
    mage_handler_run clean "$name"
  done
}

function mage_clean_help() {
  mage_help_header "Clean"
  mage_help_cmd "clean all"                   "Clean ${MAGE_CLEAN_ALL// /, } (alias: purge)"
  mage_handler_help clean "${MAGE_CLEAN_HANDLERS[@]}"
}
