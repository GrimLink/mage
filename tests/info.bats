load helper

function fake_php() {
  echo "Deprecated: some notice"
  printf '%s\n' \
    "INFO:product=Magento Community 2.4.8" \
    "INFO:mode=developer" \
    "INFO:maintenance=0" \
    "INFO:base_url=https://shop.test/" \
    "INFO:admin_url=https://shop.test/shop_admin/" \
    "INFO:database=shop" \
    "INFO:search=opensearch" \
    "INFO:php=8.3.1" \
    "INFO:modules=${MODULES:-12}" \
    "INFO:hyva=1.3.10"
}

function setup() {
  load_mage
  PHP_CLI="fake_php"
  NODE_CLI="echo v20.11.0"
}

@test "shows the project info from one Magento boot" {
  run mage_cmd_info
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "Magento Community 2.4.8 (Hyvä 1.3.10)" ]
  [[ "$output" == *"- Mode: Developer"* ]]
  [[ "$output" == *"- Maintenance: OFF"* ]]
  [[ "$output" == *"- Admin url: https://shop.test/shop_admin/"* ]]
  [[ "$output" == *"- Database: shop"* ]]
  [[ "$output" == *"- PHP: 8.3.1"* ]]
  [[ "$output" == *"- Node: 20.11.0"* ]]
  [[ "$output" == *"- Modules: 12"* ]]
  [[ "$output" != *"Deprecated"* ]]
}

@test "warns about many modules" {
  MODULES=60

  run mage_cmd_info
  [[ "$output" == *"- Modules: 60 (consider removing some for performance)"* ]]
}

@test "errors when Magento gives nothing" {
  PHP_CLI="true"

  run mage_cmd_info
  [ "$status" -eq 1 ]
}
