load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  MAGENTO_CLI="echo magento"
  COMPOSER_CLI="echo composer"
}

@test "installs the Magento sample data and cleans up after it" {
  run mage_cmd_add sample magento
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "magento sampledata:deploy" ]
  [ "${lines[1]}" = "magento setup:upgrade" ]
  [[ "$output" == *"magento indexer:reindex"*"magento cache:clean"* ]]
}

@test "asks which set, defaulting to hyva when Hyva is installed" {
  mkdir -p vendor/hyva-themes/magento2-theme-module vendor/magento/module-sample-data

  run mage_cmd_add sample <<< ""
  [[ "$output" == *"magento hyva:sampledata:deploy"* ]]
}

@test "defaults to magento without Hyva" {
  run mage_cmd_add sample <<< ""
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

@test "the Hyva set requires the sample data module when missing" {
  mkdir -p vendor/hyva-themes/magento2-theme-module

  run mage_cmd_add sample hyva
  [[ "${lines[0]}" == "composer require magento/module-sample-data" ]]
}

@test "the Hyva set keeps or replaces Luma sample data as answered" {
  mkdir -p vendor/hyva-themes/magento2-theme-module vendor/magento/module-sample-data vendor/magento/module-catalog-sample-data

  run mage_cmd_add sample hyva <<< "n"
  [[ "$output" == *"magento hyva:sampledata:deploy --keep-luma"* ]]

  run mage_cmd_add sample hyva <<< "y"
  [[ "$output" == *"magento hyva:sampledata:deploy --replace-luma"* ]]

  run mage_cmd_add sample hyva --reinstall --keep-luma
  [[ "$output" == *"magento hyva:sampledata:deploy --reinstall --keep-luma"* ]]
}
