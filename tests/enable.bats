load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  MAGENTO_CLI="echo magento"
  mkdir -p app/etc
  cat > app/etc/config.php <<'PHP'
<?php
return [
    'modules' => [
        'Magento_Catalog' => 1,
        'Hyva_Theme' => 1,
        'Hyva_Checkout' => 0,
        'Vendor_HyvaCompat' => 0,
    ],
];
PHP
}

@test "passes a module name as is" {
  run mage_cmd_module enable Vendor_Module --clear-static-content
  [ "$output" = "magento module:enable Vendor_Module --clear-static-content" ]
}

@test "enables the disabled modules matching a term after confirming" {
  run mage_cmd_module enable hyva <<< "y"
  [[ "$output" == *"Hyva_Checkout"* ]]
  [[ "$output" == *"magento module:enable Hyva_Checkout Vendor_HyvaCompat"* ]]
  [[ "$output" != *"Hyva_Theme"* ]]
}

@test "disables only enabled modules, with options passed on" {
  run mage_cmd_module disable hyva -y --clear-static-content
  [ "$output" = "$(printf 'Matching modules:\n  Hyva_Theme\nmagento module:disable --clear-static-content Hyva_Theme')" ]
}

@test "changes nothing when not confirmed" {
  run mage_cmd_module disable catalog <<< "n"
  [ "$status" -eq 0 ]
  [[ "$output" != *"module:disable"* ]]
}

@test "refuses options without a term" {
  run mage_cmd_module enable -y
  [ "$status" -eq 1 ]
  [[ "$output" != *"module:enable"* ]]
}

@test "errors without a match" {
  run mage_cmd_module enable nothing-like-this
  [ "$status" -eq 1 ]
}
