load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  MAGE_YES=0
}

@test "a question without an answer stops with an error" {
  run mage_ask "Question" "default" < /dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *"No answer for: Question"* ]]

  run mage_confirm "Sure?" y < /dev/null
  [ "$status" -eq 1 ]
}

@test "an empty answer still takes the default" {
  run mage_ask "Question" "default" <<< ""
  [ "$output" = "default" ]
}

@test "MAGE_YES takes the defaults without asking" {
  MAGE_YES=1

  run mage_ask "Question" "default" < /dev/null
  [ "$output" = "default" ]

  run mage_confirm "Sure?" y < /dev/null
  [ "$status" -eq 0 ]

  run mage_confirm "Sure?" n < /dev/null
  [ "$status" -eq 1 ]
}

@test "MAGE_YES does not answer a question without a default" {
  MAGE_YES=1

  run mage_ask "Name" < /dev/null
  [ "$status" -eq 1 ]
}

@test "typing a name to confirm always needs an answer" {
  MAGE_YES=1

  run mage_confirm_name "shop" < /dev/null
  [ "$status" -eq 1 ]
}

@test "a theme with -y takes the defaults without a terminal" {
  run mage_add_theme Vendor/MyTheme --parent=Magento/blank -y < /dev/null
  [ "$status" -eq 0 ]
  [ -f app/design/frontend/Vendor/my-theme/theme.xml ]
}

@test "a theme without the answers stops instead of guessing" {
  run mage_add_theme Vendor/MyTheme --parent=Magento/blank < /dev/null
  [ "$status" -eq 1 ]
  [ ! -e app/design/frontend/Vendor/my-theme ]
}

@test "shows modules, themes and logs as json" {
  echo '{ "require": { "vendor/module": "*" } }' > composer.json
  mkdir -p vendor/vendor/module app/etc var/log
  printf "<?php\nComponentRegistrar::register(\n    ComponentRegistrar::MODULE,\n    'Vendor_Module',\n    __DIR__\n);\n" > vendor/vendor/module/registration.php
  printf "<?php\nreturn ['modules' => [\n'Vendor_Module' => 0,\n]];\n" > app/etc/config.php
  printf 'abc' > var/log/system.log

  run mage_cmd_show modules --json
  [ "$(jq -r '.[0].name' <<< "$output")" = "Vendor_Module" ]
  [ "$(jq -r '.[0].enabled' <<< "$output")" = "false" ]

  run mage_cmd_show themes --json
  [ "$output" = "[]" ]

  run mage_cmd_show logs --json
  [ "$(jq -c '.' <<< "$output")" = '[{"name":"system","bytes":3}]' ]
}

@test "shows the info as json" {
  function fake_php() {
    printf '%s\n' "INFO:product=Magento Community 2.4.8" "INFO:mode=developer" "INFO:maintenance=0" "INFO:php=8.3.1" "INFO:modules=12"
  }
  PHP_CLI="fake_php"
  NODE_CLI="echo v20.11.0"

  run mage_cmd_info --json
  [ "$(jq -r '.product' <<< "$output")" = "Magento Community 2.4.8" ]
  [ "$(jq -r '.maintenance' <<< "$output")" = "false" ]
  [ "$(jq -r '.modules' <<< "$output")" = "12" ]
  [ "$(jq -r '.hyva' <<< "$output")" = "null" ]
}
