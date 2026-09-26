MAGE_OUTDATED_FILE="composer-outdated.json"

# Write the direct dependencies with a newer version to composer-outdated.json,
# or with --terminal show them. Further arguments go to composer.
function mage_cmd_outdated() {
  local terminal=0
  local args=()
  local arg

  for arg in "$@"; do
    case "$arg" in
      --terminal) terminal=1 ;;
      *) args+=("$arg") ;;
    esac
  done

  local ignore=()
  local package

  for package in "${MAGE_OUTDATED_IGNORE[@]}"; do
    ignore+=(--ignore "$package")
  done

  if [[ $terminal == 1 ]]; then
    $COMPOSER_CLI outdated --direct --no-dev "${ignore[@]}" "${args[@]}"
    return
  fi

  $COMPOSER_CLI outdated --direct --no-dev "${ignore[@]}" --format json "${args[@]}" > "$MAGE_OUTDATED_FILE" || return 1
  mage_check 0 "Written to ${MAGE_OUTDATED_FILE}"
}
