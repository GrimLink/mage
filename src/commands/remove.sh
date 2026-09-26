# Remove composer packages. A name with a slash is passed as is to composer remove,
# otherwise each argument is a term, matching every direct dependency that contains it.
function mage_cmd_remove() {
  if [[ $# -eq 0 ]]; then
    mage_error "Nothing to remove, give a package name or a term, such as 'mage del hyva'"
    exit 1
  fi

  if [[ "$1" == */* ]]; then
    $COMPOSER_CLI remove "$@"
    return
  fi

  local assume_yes=0
  local terms=()
  local arg

  for arg in "$@"; do
    case "$arg" in
      -y | --yes) assume_yes=1 ;;
      -*)
        mage_error "Unknown option '${arg}'"
        exit 1
        ;;
      *) terms+=("$arg") ;;
    esac
  done

  if ! command -v jq &> /dev/null; then
    mage_error "Removing by term requires jq, install it with 'brew install jq' or your package manager"
    exit 1
  fi

  local require=()
  local require_dev=()
  local package

  while IFS= read -r package; do
    require+=("$package")
  done < <(mage_remove_matches require "${terms[@]}")

  while IFS= read -r package; do
    require_dev+=("$package")
  done < <(mage_remove_matches require-dev "${terms[@]}")

  if [[ ${#require[@]} -eq 0 ]] && [[ ${#require_dev[@]} -eq 0 ]]; then
    mage_error "No direct dependency matches: ${terms[*]}"
    exit 1
  fi

  mage_info "Matching packages:"
  for package in "${require[@]}"; do
    mage_info "  ${package}"
  done
  for package in "${require_dev[@]}"; do
    mage_info "  ${package} (dev)"
  done

  if [[ $assume_yes == 0 ]] && ! mage_confirm "Remove these packages?"; then
    exit 0
  fi

  if [[ ${#require[@]} -gt 0 ]]; then
    $COMPOSER_CLI remove "${require[@]}" || exit 1
  fi

  if [[ ${#require_dev[@]} -gt 0 ]]; then
    $COMPOSER_CLI remove --dev "${require_dev[@]}" || exit 1
  fi
}

# Echo the packages in the composer.json key that contain any of the terms,
# case-insensitive and as plain text. Platform entries like php and ext-* have no slash.
function mage_remove_matches() {
  local key="$1"
  shift

  local patterns=()
  local term

  for term in "$@"; do
    patterns+=(-e "$term")
  done

  jq -r --arg key "$key" '.[$key] // {} | keys[] | select(contains("/"))' composer.json |
    grep -i -F "${patterns[@]}"
}
