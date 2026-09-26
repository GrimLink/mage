load helper

function fake_magento() {
  case "$1" in
    config:show) echo "https://shop.test/" ;;
    *) echo "magento $*" ;;
  esac
}

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  MAGENTO_CLI="fake_magento"
  function mage_add_store_view() { echo "store view $1"; }
}

@test "creates a store view on a prefix of the base domain" {
  run mage_cmd_add store luma
  [ "$status" -eq 0 ]
  [[ "$output" == *"store view luma"* ]]
  [[ "$output" == *"magento config:set --scope=stores --scope-code=luma web/secure/base_url https://luma.shop.test/"* ]]
  [[ "$output" == *"magento indexer:reindex design_config_grid"* ]]
  [[ "$output" == *"MAGE_RUN_CODE=luma"* ]]
}

@test "uses a full domain as is, with its first part as the code" {
  run mage_cmd_add store b2b.example.test
  [[ "$output" == *"--scope-code=b2b web/secure/base_url https://b2b.example.test/"* ]]
}

@test "turns dashes into underscores for the code" {
  run mage_cmd_add store my-store
  [[ "$output" == *"--scope-code=my_store web/secure/base_url https://my-store.shop.test/"* ]]
}

@test "refuses an invalid store code" {
  run mage_cmd_add store 1store
  [ "$status" -eq 1 ]
  [[ "$output" == *"not a valid store code"* ]]
}

@test "adds the store to valet by its site name" {
  use_stub_bins valet
  echo "<?php declare(strict_types=1);

return [
	'shop' => [
		'MAGE_RUN_CODE' => 'default',
		'MAGE_RUN_TYPE' => 'store',
	],
];" > .valet-env.php
  mage_env_use valet

  run mage_cmd_add store luma
  [ "$status" -eq 0 ]
  grep -q "'luma.shop' => \[" .valet-env.php
  grep -q "'MAGE_RUN_CODE' => 'luma'" .valet-env.php
  grep -q "'shop' => \[" .valet-env.php
  [ "$(tail -n 1 .valet-env.php)" = "];" ]
}
