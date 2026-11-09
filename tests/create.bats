load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  COMPOSER_CLI="fake_composer"
  MAGE_CALL_DIR="$BATS_TEST_TMPDIR"
  echo '{ "name": "acme/project" }' > composer.json
}

@test "applies the development defaults before the install" {
  run mage_create_composer_setup
  [ "$status" -eq 0 ]
  [[ "$output" == *"Adding Development defaults"* ]]
  [[ "$output" == *"composer config allow-plugins.cweagans/composer-patches true"* ]]
  [ "${lines[${#lines[@]}-1]}" = "composer install" ]
  jq -e '.replace["mage-os/module-passkey-auth"] == "*"' composer.json
}

@test "warns and still installs without the template" {
  function mage_template_file() { return 1; }

  run mage_create_composer_setup
  [ "$status" -eq 0 ]
  [[ "$output" == *"Skipping the development defaults"* ]]
  [ "${lines[${#lines[@]}-1]}" = "composer install" ]
  jq -e 'has("replace") | not' composer.json
}

@test "syncs the templates when they miss the create fragment" {
  MAGE_VERSION="1.0.0"
  function mage_template_file() { return 1; }
  function mage_sync_templates() { echo "sync $1"; }

  run mage_cmd_create acme -y --env=unknown
  [[ "$output" == *"sync $(mage_config_dir)/templates"* ]]
  [ ! -e acme ]
}

@test "keeps the templates that have the create fragment" {
  MAGE_VERSION="1.0.0"
  function mage_template_file() { echo "composer-create.json"; }
  function mage_sync_templates() { echo "sync"; }

  run mage_cmd_create acme -y --env=unknown
  [[ "$output" != *"sync"* ]]
}
