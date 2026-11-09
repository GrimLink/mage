load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
}

@test "runs the cache-clean of the project as an executable" {
  mkdir -p vendor/bin
  printf '#!/bin/sh\necho "project $*"\n' > vendor/bin/cache-clean.js
  chmod +x vendor/bin/cache-clean.js

  run mage_cmd_watch
  [ "$output" = "project --watch" ]
}

@test "runs the cache-clean of the project in the warden container" {
  mkdir -p vendor/bin
  touch vendor/bin/cache-clean.js

  function warden() { echo "warden $*"; }
  mage_env_use warden

  run mage_cmd_watch
  [ "$output" = "warden env exec php-fpm vendor/bin/cache-clean.js --watch" ]
}

@test "runs the cache-clean of the project in the ddev container" {
  mkdir -p vendor/bin
  touch vendor/bin/cache-clean.js

  function ddev() { echo "ddev $*"; }
  mage_env_use ddev

  run mage_cmd_watch
  [ "$output" = "ddev exec vendor/bin/cache-clean.js --watch" ]
}

@test "ignores arguments" {
  make_magento_root "$BATS_TEST_TMPDIR"
  CACHE_CLEAN_CLI="echo cache-clean.js"
  mkdir -p vendor/bin
  touch vendor/bin/cache-clean.js

  run mage_main watch anything
  [ "$output" = "cache-clean.js --watch" ]
}

@test "falls back to a global cache-clean" {
  use_stub_bins
  printf '#!/bin/sh\necho "global $*"\n' > "${BATS_TEST_TMPDIR}/bin/cache-clean.js"
  chmod +x "${BATS_TEST_TMPDIR}/bin/cache-clean.js"

  run mage_cmd_watch
  [ "$output" = "global --watch" ]
}

@test "errors without any cache-clean" {
  use_stub_bins

  run mage_cmd_watch
  [ "$status" -eq 1 ]
  [[ "$output" == *"mage add mage-os/magento-cache-clean --dev"* ]]
}
