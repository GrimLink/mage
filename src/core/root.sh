MAGE_ROOT=""
MAGE_CALL_DIR="$PWD"

# Echo the Magento root at or above the given folder
function mage_find_root() {
  local dir="${1:-$PWD}"

  while true; do
    if [[ -f "${dir}/bin/magento" ]] && [[ -f "${dir}/app/etc/di.xml" ]]; then
      echo "$dir"
      return 0
    fi

    if [[ "$dir" == "/" ]] || [[ -z "$dir" ]]; then
      return 1
    fi

    dir="$(dirname "$dir")"
  done
}

# Move to the Magento root, when called from a nested folder
function mage_root_enter() {
  MAGE_ROOT="$(mage_find_root "$PWD")"

  if [[ -z "$MAGE_ROOT" ]]; then
    mage_error "This does not look like a Magento 2 project, aborting.."
    mage_info "Run 'mage help' to see what mage can do"
    return 1
  fi

  if [[ "$MAGE_ROOT" != "$PWD" ]]; then
    mage_notice "Running from ${MAGE_ROOT}"
    cd "$MAGE_ROOT" || return 1
  fi
}

# Echo a path given from the calling folder, relative to the Magento root.
# Relative to the root, it works the same on the host and inside a container.
function mage_resolve_path() {
  local path="$1"

  if [[ "$path" == /* ]] || [[ "$MAGE_CALL_DIR" == "$MAGE_ROOT" ]]; then
    echo "$path"
  elif [[ "$MAGE_CALL_DIR" == "$MAGE_ROOT"/* ]]; then
    echo "${MAGE_CALL_DIR#"$MAGE_ROOT"/}/${path}"
  else
    echo "${MAGE_CALL_DIR}/${path}"
  fi
}

# Run bin/magento, where arguments starting with ./ or ../ are
# resolved from the calling folder
function mage_passthrough() {
  local args=()
  local arg

  for arg in "$@"; do
    case "$arg" in
      "." | ".." | ./* | ../*)
        args+=("$(mage_resolve_path "$arg")")
        ;;
      *)
        args+=("$arg")
        ;;
    esac
  done

  $MAGENTO_CLI "${args[@]}"
}
