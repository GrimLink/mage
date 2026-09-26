# Update composer packages. Without arguments or with a package name (a slash),
# everything is passed as is to composer update. Otherwise each argument is a term,
# updating every direct dependency that contains it, options go to composer.
function mage_cmd_update() {
  if [[ $# -eq 0 ]] || [[ "$1" == */* ]] || [[ "$1" == -* ]]; then
    $COMPOSER_CLI update "$@"
    return
  fi

  local terms=()
  local options=()
  local arg

  for arg in "$@"; do
    case "$arg" in
      -*) options+=("$arg") ;;
      *) terms+=("$arg") ;;
    esac
  done

  mage_require_jq "Updating by term"

  local packages=()
  local package

  while IFS= read -r package; do
    packages+=("$package")
  done < <(mage_composer_matches require "${terms[@]}"; mage_composer_matches require-dev "${terms[@]}")

  if [[ ${#packages[@]} -eq 0 ]]; then
    mage_error "No direct dependency matches: ${terms[*]}"
    exit 1
  fi

  mage_info "Updating: ${packages[*]}"
  $COMPOSER_CLI update "${options[@]}" "${packages[@]}"
}
