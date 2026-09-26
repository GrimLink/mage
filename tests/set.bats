load helper

function setup() {
  load_mage
  MAGENTO_CLI="echo magento"
}

@test "errors without an option, listing the handlers" {
  run mage_cmd_set
  [ "$status" -eq 1 ]
  [[ "$output" == *"set csp"* ]]
  [[ "$output" == *"set fpc"* ]]
}

@test "enforces a strict CSP in env.php" {
  run mage_cmd_set csp
  [ "$status" -eq 0 ]
  [[ "$output" == *"magento config:set --lock-env csp/mode/storefront/report_only 0"* ]]
  [[ "$output" == *"magento config:set --lock-env csp/policies/storefront/scripts/inline 0"* ]]
  [[ "$output" == *"magento config:set --lock-env csp/policies/storefront/scripts/eval 0"* ]]
  [[ "$output" == *"magento cache:flush config"* ]]
}

@test "sets the full page cache" {
  run mage_cmd_set fpc
  [ "$output" = "magento config:set system/full_page_cache/caching_application 1" ]

  run mage_cmd_set fpc default
  [ "$output" = "magento config:set system/full_page_cache/caching_application 1" ]

  run mage_cmd_set fpc varnish
  [ "$output" = "magento config:set system/full_page_cache/caching_application 2" ]
}

@test "rejects an unknown full page cache" {
  run mage_cmd_set fpc redis
  [ "$status" -eq 1 ]
}
