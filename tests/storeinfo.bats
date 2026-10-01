load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  COMPOSER_CLI="echo composer"
  MAGENTO_CLI="echo magento"
  MAGE_ROOT="$BATS_TEST_TMPDIR"
  MAGE_CALL_DIR="$BATS_TEST_TMPDIR"
}

@test "requires the StoreInfo modules and upgrades" {
  run mage_cmd_add storeinfo
  [ "$status" -eq 0 ]
  [[ "$output" == *"composer require siteation/magento2-storeinfo:* siteation/magento2-storeinfo-menus:* siteation/magento2-storeinfo-usps:* siteation/magento2-storeinfo-payments:*"* ]]
  [[ "$output" == *"magento setup:upgrade"* ]]
}

@test "rejects options" {
  run mage_cmd_add storeinfo --dev
  [ "$status" -eq 1 ]
}
