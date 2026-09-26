load helper

function setup() {
  load_mage
}

@test "errors without an option, listing the handlers" {
  run mage_cmd_show
  [ "$status" -eq 1 ]
  [[ "$output" == *"show stores"* ]]
}

@test "errors on an unknown option" {
  run mage_cmd_show nope
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown show option 'nope'"* ]]
}

@test "shows the stores through magerun" {
  MAGERUN_CLI="echo magerun"

  run mage_cmd_show stores --format=json
  [ "$output" = "magerun sys:store:config:base-url:list --format txt --format=json" ]
}

# Write a registration.php for a component, over several lines like Magento does
function make_registration() {
  mkdir -p "$1"
  printf "<?php\n\nComponentRegistrar::register(\n    ComponentRegistrar::%s,\n    '%s',\n    __DIR__\n);\n" "$2" "$3" > "$1/registration.php"
}

@test "shows only the modules of the direct dependencies and app/code" {
  cd "$BATS_TEST_TMPDIR"
  echo '{ "require": { "php": "*", "vendor/module": "*", "vendor/theme": "*", "vendor/meta": "*" }, "require-dev": { "vendor/dev": "*" } }' > composer.json
  make_registration vendor/vendor/module MODULE Vendor_Module
  make_registration vendor/vendor/module/src/Second MODULE Vendor_Second
  make_registration vendor/vendor/theme THEME frontend/Vendor/theme
  mkdir -p vendor/vendor/meta
  make_registration vendor/vendor/dev MODULE Vendor_Dev
  make_registration vendor/other/indirect MODULE Other_Indirect
  make_registration app/code/Custom/Thing MODULE Custom_Thing
  mkdir -p app/etc
  printf "<?php\nreturn ['modules' => [\n'Vendor_Second' => 0,\n]];\n" > app/etc/config.php

  run mage_cmd_show modules
  [ "$status" -eq 0 ]
  [[ "$output" == *"Custom_Thing"*"app/code"* ]]
  [[ "$output" == *"Vendor_Dev"*"vendor/dev"* ]]
  [[ "$output" == *"Vendor_Second"*"vendor/module (disabled)"* ]]
  [[ "$output" == *"Vendor_Module"*"vendor/module"* ]]
  [[ "$output" != *"Other_Indirect"* ]]
  [[ "$output" != *"frontend/Vendor/theme"* ]]
}

@test "shows only the themes of the direct dependencies and app/design, with their parent" {
  cd "$BATS_TEST_TMPDIR"
  echo '{ "require": { "vendor/theme": "*", "vendor/module": "*" } }' > composer.json
  make_registration vendor/vendor/theme THEME frontend/Vendor/theme-name
  printf '<theme>\n    <title>Theme</title>\n    <parent>Hyva/default</parent>\n</theme>\n' > vendor/vendor/theme/theme.xml
  make_registration vendor/vendor/module MODULE Vendor_Module
  make_registration vendor/other/indirect THEME frontend/Other/indirect
  make_registration app/design/adminhtml/Custom/admin THEME adminhtml/Custom/admin

  run mage_cmd_show themes
  [ "$status" -eq 0 ]
  [[ "$output" == *"adminhtml/Custom/admin"*"app/design"* ]]
  [[ "$output" == *"frontend/Vendor/theme-name"*"vendor/theme"*"parent: Hyva/default"* ]]
  [[ "$output" != *"Vendor_Module"* ]]
  [[ "$output" != *"Other/indirect"* ]]
}

@test "says so when there are no modules" {
  cd "$BATS_TEST_TMPDIR"
  echo '{ "require": {} }' > composer.json

  run mage_cmd_show modules
  [ "$status" -eq 0 ]
  [[ "$output" == *"No modules found"* ]]
}

@test "shows the full page cache by name" {
  function varnish_magento() { echo "2"; }
  MAGENTO_CLI="varnish_magento"
  run mage_cmd_show fpc
  [ "$output" = "varnish" ]

  MAGENTO_CLI="true"
  run mage_cmd_show fpc
  [ "$output" = "builtin" ]
}
