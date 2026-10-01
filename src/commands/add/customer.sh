MAGE_ADD_HANDLERS+=("customer|Create a customer through magerun, arguments go to its customer:create")

# Magento has no command for this, magerun asks for anything not given
function mage_add_customer() {
  check_has_magerun
  $MAGERUN_CLI customer:create "$@"
}
