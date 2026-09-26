# Show the direct dependencies with a newer version, further arguments go to composer
function mage_cmd_outdated() {
  local ignore=()
  local package

  for package in "${MAGE_OUTDATED_IGNORE[@]}"; do
    ignore+=(--ignore "$package")
  done

  $COMPOSER_CLI outdated --direct --no-dev "${ignore[@]}" "$@"
}
