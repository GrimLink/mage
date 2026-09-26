load helper

function setup() {
  BUILD="${BATS_TEST_TMPDIR}/mage"
  export XDG_CONFIG_HOME="${BATS_TEST_TMPDIR}/config"
  "${MAGE_REPO}/src/build.sh" "$BUILD" > /dev/null
}

@test "builds a single valid script" {
  [ -x "$BUILD" ]
  bash -n "$BUILD"
  ! grep -q 'source "${MAGE_SRC}' "$BUILD"
  ! grep -q '^MAGE_SRC=' "$BUILD"
}

@test "takes the version from the changelog" {
  local version
  version="$(grep -m1 -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "${MAGE_REPO}/CHANGELOG.md" | tr -d '#[] ')"

  grep -q "^MAGE_VERSION=\"${version}\"$" "$BUILD"
}

@test "runs version and help outside a Magento project" {
  cd "$BATS_TEST_TMPDIR"

  run "$BUILD" version
  [ "$status" -eq 0 ]

  run "$BUILD" help
  [ "$status" -eq 0 ]
}

@test "aborts other commands outside a Magento project" {
  cd "$BATS_TEST_TMPDIR"

  run "$BUILD" cache:flush
  [ "$status" -eq 1 ]
}
