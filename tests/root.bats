load helper

function setup() {
  load_mage
  ROOT="${BATS_TEST_TMPDIR}/project"
  make_magento_root "$ROOT"
  mkdir -p "${ROOT}/app/code/Vendor"
}

@test "finds the root from the root" {
  run mage_find_root "$ROOT"
  [ "$status" -eq 0 ]
  [ "$output" = "$ROOT" ]
}

@test "finds the root from a nested folder" {
  run mage_find_root "${ROOT}/app/code/Vendor"
  [ "$status" -eq 0 ]
  [ "$output" = "$ROOT" ]
}

@test "fails outside a Magento project" {
  run mage_find_root "$BATS_TEST_TMPDIR"
  [ "$status" -eq 1 ]
}

@test "needs both bin/magento and app/etc/di.xml" {
  mkdir -p "${BATS_TEST_TMPDIR}/half/bin"
  touch "${BATS_TEST_TMPDIR}/half/bin/magento"

  run mage_find_root "${BATS_TEST_TMPDIR}/half"
  [ "$status" -eq 1 ]
}

@test "enters the root from a nested folder" {
  cd "${ROOT}/app/code/Vendor"
  mage_root_enter 2> /dev/null

  [ "$PWD" = "$ROOT" ]
  [ "$MAGE_ROOT" = "$ROOT" ]
}

@test "aborts outside a Magento project" {
  cd "$BATS_TEST_TMPDIR"
  run mage_root_enter
  [ "$status" -eq 1 ]
}

@test "resolves paths relative to the root" {
  MAGE_ROOT="$ROOT"
  MAGE_CALL_DIR="${ROOT}/app/code"

  [ "$(mage_resolve_path ./Vendor)" = "app/code/./Vendor" ]
  [ "$(mage_resolve_path /tmp/x)" = "/tmp/x" ]

  MAGE_CALL_DIR="$ROOT"
  [ "$(mage_resolve_path ./Vendor)" = "./Vendor" ]
}

@test "passes relative path arguments through resolved" {
  MAGE_ROOT="$ROOT"
  MAGE_CALL_DIR="${ROOT}/app/code"
  MAGENTO_CLI="echo"

  run mage_passthrough i18n:collect-phrases ./Vendor --output=x.csv
  [ "$output" = "i18n:collect-phrases app/code/./Vendor --output=x.csv" ]
}
