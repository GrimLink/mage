load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  COMPOSER_CLI="echo composer"
  MAGENTO_CLI="echo magento"
  MAGE_ROOT="$BATS_TEST_TMPDIR"
  MAGE_CALL_DIR="$BATS_TEST_TMPDIR"
  MAGE_VAR_HYVA_PROJECT="acme"
  MAGE_VAR_HYVA_LICENSE_KEY="key"
}

@test "adds Hyva with a license" {
  run mage_cmd_add hyva <<< "$(printf '\n\n')"
  [ "$status" -eq 0 ]
  [[ "$output" == *"hyva-themes.repo.packagist.com/acme/"* ]]
  [[ "$output" == *"magento setup:upgrade"* ]]
  [[ "$output" == *"Select the Hyva/default theme in the admin"* ]]
}

@test "adds Hyva from the GitLab with --dev" {
  run mage_cmd_add hyva --dev
  [ "$status" -eq 0 ]
  [[ "$output" == *"git@gitlab.hyva.io:hyva-themes/magento2-theme-module.git"* ]]
  [[ "$output" != *"--auth"* ]]
}

@test "rejects unknown options" {
  run mage_cmd_add hyva checkout
  [ "$status" -eq 1 ]
}
