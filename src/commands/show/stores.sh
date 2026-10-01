MAGE_SHOW_HANDLERS+=("stores|Show the stores with their base urls, requires magerun")

# Further arguments go to magerun, such as --format=json
function mage_show_stores() {
  check_has_magerun
  $MAGERUN_CLI sys:store:config:base-url:list --format txt "$@"
}
