# Enable or disable modules. A module name (with an underscore) is passed as is,
# otherwise each argument is a term, matching the modules in app/etc/config.php
# that contain it and can change: disabled ones to enable, enabled ones to disable.
function mage_cmd_module() {
  local action="$1"
  shift

  if [[ $# -eq 0 ]]; then
    mage_error "Nothing to ${action}, give a module name or a term, such as 'mage ${action} hyva'"
    exit 1
  fi

  if [[ "$1" == *_* ]]; then
    $MAGENTO_CLI "module:${action}" "$@"
    return
  fi

  local terms=()
  local options=()
  local arg

  for arg in "$@"; do
    case "$arg" in
      -y | --yes) MAGE_YES=1 ;;
      -*) options+=("$arg") ;;
      *) terms+=("$arg") ;;
    esac
  done

  # Without a term the empty pattern would match every module
  if [[ ${#terms[@]} -eq 0 ]]; then
    mage_error "Give a module name or a term to ${action}"
    exit 1
  fi

  local state=0
  if [[ "$action" == "disable" ]]; then
    state=1
  fi

  local modules=()
  local module

  while IFS= read -r module; do
    modules+=("$module")
  done < <(mage_config_modules "$state" | grep -i -F "$(printf '%s\n' "${terms[@]}")")

  if [[ ${#modules[@]} -eq 0 ]]; then
    mage_error "No module to ${action} matches: ${terms[*]}"
    exit 1
  fi

  mage_info "Matching modules:"
  for module in "${modules[@]}"; do
    mage_info "  ${module}"
  done

  if [[ $MAGE_YES != 1 ]] && ! mage_confirm "Run module:${action} for these modules?"; then
    exit 0
  fi

  $MAGENTO_CLI "module:${action}" "${options[@]}" "${modules[@]}"
}

# Echo the modules in app/etc/config.php with the given state, 1 enabled or 0 disabled
function mage_config_modules() {
  grep -o "'[A-Za-z0-9_]*' => $1" app/etc/config.php 2> /dev/null | cut -d "'" -f 2
}
