load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  COMPOSER_CLI="echo composer"
  MAGENTO_CLI="echo magento"
  NPM_CLI="echo npm"
  MAGE_ROOT="$BATS_TEST_TMPDIR"
  MAGE_CALL_DIR="$BATS_TEST_TMPDIR"
  MAGE_VAR_HYVA_PROJECT="acme"
  MAGE_VAR_HYVA_LICENSE_KEY="key"
}

@test "adds Hyva with a license and activates it" {
  mkdir -p vendor/yireo/magento2-theme-commands vendor/hyva-themes/magento2-default-theme/web/tailwind

  run mage_cmd_add hyva <<< "$(printf '\n\n')"
  [ "$status" -eq 0 ]
  [[ "$output" == *"hyva-themes.repo.packagist.com/acme/"* ]]
  [[ "$output" == *"magento setup:upgrade"* ]]
  [[ "$output" == *"magento theme:change Hyva/default"* ]]
  [[ "$output" == *"npm --prefix vendor/hyva-themes/magento2-default-theme/web/tailwind install"* ]]
  [[ "$output" == *"npm --prefix vendor/hyva-themes/magento2-default-theme/web/tailwind run build"* ]]
}

@test "adds Hyva from the GitLab with --dev" {
  run mage_cmd_add hyva --dev
  [ "$status" -eq 0 ]
  [[ "$output" == *"git@gitlab.hyva.io:hyva-themes/magento2-theme-module.git"* ]]
  [[ "$output" != *"--auth"* ]]
}

@test "points to the admin without the theme commands" {
  run mage_cmd_add hyva --dev
  [[ "$output" == *"Select the Hyva/default theme in the admin"* ]]
  [[ "$output" != *"theme:change"* ]]
}

@test "builds the CSP theme when installed" {
  mkdir -p vendor/hyva-themes/magento2-default-theme-csp/web/tailwind/node_modules

  run mage_hyva_build
  [ "$output" = "npm --prefix vendor/hyva-themes/magento2-default-theme-csp/web/tailwind run build" ]
}

@test "rejects unknown options" {
  run mage_cmd_add hyva checkout
  [ "$status" -eq 1 ]
}
