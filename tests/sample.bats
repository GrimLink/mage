load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  MAGENTO_CLI="echo magento"
  COMPOSER_CLI="echo composer"
}

@test "installs the Magento sample data and cleans up after it" {
  run mage_cmd_add sample magento <<< "y"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "magento sampledata:deploy" ]
  [ "${lines[1]}" = "magento setup:upgrade" ]
  [[ "$output" == *"Cleared design/head/includes"*"magento indexer:reindex"*"magento cache:clean"* ]]
}

@test "keeps the head styles when asked" {
  run mage_cmd_add sample magento <<< "n"
  [ "$status" -eq 0 ]
  [[ "$output" != *"Cleared design/head/includes"* ]]
}

@test "asks which set, defaulting to hyva when Hyva is installed" {
  mkdir -p vendor/hyva-themes/magento2-theme-module

  run mage_cmd_add sample <<< $'\n'
  [[ "$output" == *"magento hyva:sampledata:deploy"* ]]
}

@test "defaults to magento without Hyva" {
  run mage_cmd_add sample <<< $'\n'
  [[ "$output" == *"magento sampledata:deploy"* ]]
}

@test "refuses an unknown set" {
  run mage_cmd_add sample luma
  [ "$status" -eq 1 ]
  [[ "$output" == *"use one of: magento hyva"* ]]
}

@test "the Hyva set needs Hyva" {
  run mage_cmd_add sample hyva
  [ "$status" -eq 1 ]
  [[ "$output" == *"mage add hyva"* ]]
}

@test "the Hyva set adds the Koti GitLab repositories without a Hyva license" {
  mkdir -p vendor/hyva-themes/magento2-theme-module
  MAGE_ROOT="$BATS_TEST_TMPDIR"
  MAGE_CALL_DIR="$BATS_TEST_TMPDIR"

  echo '{ "repositories": { "local-packages": { "type": "path", "url": "package-source/*/*" } } }' > composer.json
  run mage_cmd_add sample hyva <<< "y"
  [[ "$output" == *"composer config repositories.koti-sample-data-catalog"*"gitlab.hyva.io:hyva-themes/sample-data/koti/koti-sample-data-catalog.git"* ]]
  [[ "$output" == *"magento hyva:sampledata:deploy"* ]]

  echo '{ "repositories": { "private-packagist": { "type": "composer", "url": "https://hyva-themes.repo.packagist.com/acme/" } } }' > composer.json
  run mage_cmd_add sample hyva <<< "y"
  [[ "$output" != *"koti-sample-data"* ]]
  [[ "$output" == *"magento hyva:sampledata:deploy"* ]]
}

@test "the Hyva set keeps or replaces Luma sample data as answered" {
  mkdir -p vendor/hyva-themes/magento2-theme-module vendor/magento/module-catalog-sample-data
  echo '{ "repositories": { "private-packagist": { "type": "composer", "url": "https://hyva-themes.repo.packagist.com/acme/" } } }' > composer.json

  run mage_cmd_add sample hyva <<< $'n\ny'
  [[ "$output" == *"magento hyva:sampledata:deploy --keep-luma"* ]]

  run mage_cmd_add sample hyva <<< $'y\ny'
  [[ "$output" == *"magento hyva:sampledata:deploy --replace-luma"* ]]

  run mage_cmd_add sample hyva --reinstall --keep-luma <<< "y"
  [[ "$output" == *"magento hyva:sampledata:deploy --reinstall --keep-luma"* ]]
}
