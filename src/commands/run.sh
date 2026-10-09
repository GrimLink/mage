# Run n98-magerun2 with the given arguments
function mage_cmd_run() {
  check_has_magerun
  $MAGERUN_CLI "$@"
}
