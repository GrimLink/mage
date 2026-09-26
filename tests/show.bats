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

@test "says so when there are no modules" {
  cd "$BATS_TEST_TMPDIR"
  echo '{ "require": {} }' > composer.json

  run mage_cmd_show modules
  [ "$status" -eq 0 ]
  [[ "$output" == *"No modules found"* ]]
}
