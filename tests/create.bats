load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  COMPOSER_CLI="fake_composer"
  MAGE_CALL_DIR="$BATS_TEST_TMPDIR"
  echo '{ "name": "acme/project" }' > composer.json
}

@test "replaces the Mage-OS modules mage leaves out before the install" {
  run mage_create_composer_setup mage-os
  [ "$status" -eq 0 ]
  [[ "$output" == *"Adding Mage-OS module removals"* ]]
  [ "${lines[${#lines[@]}-1]}" = "composer install" ]
  jq -e '.replace == { "mage-os/module-passkey-auth": "*", "mage-os/module-theme-optimization": "*" }' composer.json
}

@test "replaces nothing for the other editions" {
  run mage_create_composer_setup community
  [ "$status" -eq 0 ]
  [[ "$output" == *"composer config allow-plugins.cweagans/composer-patches true"* ]]
  [ "${lines[${#lines[@]}-1]}" = "composer install" ]
  jq -e 'has("replace") | not' composer.json
}

@test "warns and still installs without the Mage-OS template" {
  function mage_template_file() { return 1; }

  run mage_create_composer_setup mage-os
  [ "$status" -eq 0 ]
  [[ "$output" == *"Keeping all Mage-OS modules"* ]]
  [ "${lines[${#lines[@]}-1]}" = "composer install" ]
  jq -e 'has("replace") | not' composer.json
}

@test "syncs the templates when they miss the Mage-OS template" {
  MAGE_VERSION="1.0.0"
  function mage_template_file() { return 1; }
  function mage_sync_templates() { echo "sync $1"; }

  run mage_cmd_create acme -y --edition=mage-os --env=unknown
  [[ "$output" == *"sync $(mage_config_dir)/templates"* ]]
  [ ! -e acme ]
}

@test "never syncs the templates for the other editions" {
  MAGE_VERSION="1.0.0"
  function mage_template_file() { return 1; }
  function mage_sync_templates() { echo "sync"; }

  run mage_cmd_create acme -y --edition=community --env=unknown
  [[ "$output" != *"sync"* ]]
}
