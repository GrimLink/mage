load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  COMPOSER_CLI="echo composer"
  cat > composer.json <<'JSON'
{
  "require": {
    "php": "~8.3",
    "hyva-themes/magento2-default-theme": "*",
    "siteation/magento2-storeinfo": "*"
  },
  "require-dev": {
    "hyva-themes/magento2-dev-tools": "*"
  }
}
JSON
}

@test "updates everything without arguments" {
  run mage_cmd_update
  [ "$output" = "composer update" ]
}

@test "passes a package name and options as is" {
  run mage_cmd_update vendor/package -W
  [ "$output" = "composer update vendor/package -W" ]

  run mage_cmd_update --lock
  [ "$output" = "composer update --lock" ]
}

@test "updates the matches of a term, dev packages included" {
  run mage_cmd_update hyva -W
  [[ "$output" == *"composer update -W hyva-themes/magento2-default-theme hyva-themes/magento2-dev-tools"* ]]
}

@test "errors without a match" {
  run mage_cmd_update nothing-like-this
  [ "$status" -eq 1 ]
}
