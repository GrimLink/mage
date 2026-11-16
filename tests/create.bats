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


@test "creates a magebox project, then its config and services" {
  MAGEBOX_GLOBAL_CONFIG="${BATS_TEST_TMPDIR}/magebox-config.yaml"
  function magebox() {
    echo "magebox $*"
    if [[ "$1" == "init" ]]; then
      printf 'name: %s\nservices:\n  mysql: "8.4"\n' "$2" > .magebox.yaml
    fi
  }
  function fake_create_composer() {
    echo "composer $*"
    mkdir -p "${@: -1}"
  }
  mage_env_use magebox
  COMPOSER_CLI="fake_create_composer"

  env_call create_project my-shop mage-os/project-community-edition https://repo.mage-os.org/
  [ "$(basename "$PWD")" = "my-shop" ]
  [ -f .magebox.yaml ]
  [ "$MAGE_DB_NAME" = "my_shop" ]
  [ "$MAGE_DB_HOST" = "127.0.0.1:33084" ]
}
