load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  COMPOSER_CLI="fake_composer"
  MAGE_CALL_DIR="$BATS_TEST_TMPDIR"
  echo '{ "name": "acme/project" }' > composer.json
}

@test "picks the template by edition" {
  [ "$(mage_create_default_template mage-os)" = "mage-os" ]
  [ "$(mage_create_default_template mage-os-minimal)" = "mage-os-minimal" ]
  [ "$(mage_create_default_template mage-os-mirror)" = "default" ]
  [ "$(mage_create_default_template community)" = "default" ]
}

@test "applies the template without updating before the install" {
  run mage_create_composer_setup "$(mage_create_template_file default)"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Adding the default packages"* ]]
  [[ "$output" == *"composer config allow-plugins.cweagans/composer-patches true"* ]]
  [[ "$output" == *"composer require --no-update mage-os/theme-adminhtml-m137 cweagans/composer-patches"* ]]
  [[ "$output" == *"composer require --no-update --dev avstudnitz/scopehint2"* ]]
  [ "${lines[${#lines[@]}-1]}" = "composer install" ]
  jq -e 'has("replace") | not' composer.json
}

@test "replaces the Mage-OS modules mage leaves out with the mage-os template" {
  run mage_create_composer_setup "$(mage_create_template_file mage-os)"
  [ "$status" -eq 0 ]
  [ "${lines[${#lines[@]}-1]}" = "composer install" ]
  jq -e '.replace == { "mage-os/module-passkey-auth": "*", "mage-os/module-theme-optimization": "*" }' composer.json
}

@test "takes a json file as template" {
  echo '{ "require": { "vendor/a": "*" } }' > own.json

  [ "$(mage_create_template_file own.json)" = "${BATS_TEST_TMPDIR}/own.json" ]

  run mage_create_template_file missing.json
  [ "$status" -eq 1 ]
  [[ "$output" == *"Template file not found: missing.json"* ]]
}

@test "refuses an unknown template, listing the bundled ones" {
  run mage_create_template_file unknown
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown template 'unknown', use one of: "*" or a path to a json file"* ]]
  [[ "$output" == *"default"* && "$output" == *"mage-os-minimal"* ]]
  [[ "$output" == *" mage-os,"* || "$output" == *" mage-os or"* ]]
}

@test "still requires the deprecated default packages with a warning" {
  echo '{}' > empty.json
  MAGE_PACKAGES=(vendor/a)
  MAGE_DEV_PACKAGES=(vendor/b)

  run mage_create_composer_setup "${BATS_TEST_TMPDIR}/empty.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"MAGE_PACKAGES and MAGE_DEV_PACKAGES are deprecated"* ]]
  [[ "$output" == *"composer require --no-update vendor/a"* ]]
  [[ "$output" == *"composer require --no-update --dev vendor/b"* ]]
}

@test "generates the XML catalog in a new folder" {
  MAGENTO_CLI="echo bin/magento"

  run mage_create_urn_catalog
  [ "$status" -eq 0 ]
  [ -d .vscode ]
  [ "${lines[${#lines[@]}-1]}" = "bin/magento dev:urn-catalog:generate --ide=vscode .vscode/catalog.xml" ]
}
