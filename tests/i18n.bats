load helper

function fake_magento() {
  printf 'Zebra,Zebra\n"Quoted, text","Quoted, text"\nHello,Hello\n' > "$4"
  echo "magento $1 $2"
}

function setup() {
  load_mage
  MAGE_ROOT="$BATS_TEST_TMPDIR"
  cd "$MAGE_ROOT"
  MAGENTO_CLI="fake_magento"
  mkdir -p app/code/Vendor/Module
  touch app/code/Vendor/Module/registration.php
}

@test "collects the phrases of the calling folder, quoted and sorted" {
  MAGE_CALL_DIR="${MAGE_ROOT}/app/code/Vendor/Module"

  run mage_cmd_add i18n
  [ "$status" -eq 0 ]
  [[ "$output" == *"magento i18n:collect-phrases app/code/Vendor/Module/."* ]]

  local csv="app/code/Vendor/Module/i18n/en_US.csv"
  [ "$(cat "$csv")" = "$(printf '"Hello","Hello"\n"Quoted, text","Quoted, text"\n"Zebra","Zebra"')" ]
  [ ! -e app/code/Vendor/Module/i18n/temp.csv ]
}

@test "asks before collecting outside a module or theme" {
  MAGE_CALL_DIR="$MAGE_ROOT"
  mkdir -p other

  run mage_cmd_add i18n other <<< "n"
  [ "$status" -eq 1 ]
  [ ! -e other/i18n ]
}
