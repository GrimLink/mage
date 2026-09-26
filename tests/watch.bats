load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  NODE_CLI="echo node"
}

@test "runs the cache-clean of the project through node" {
  mkdir -p vendor/bin
  touch vendor/bin/cache-clean.js

  run mage_cmd_watch --directory app/code
  [ "$output" = "node vendor/bin/cache-clean.js --watch --directory app/code" ]
}

@test "falls back to a global cache-clean" {
  use_stub_bins
  printf '#!/bin/sh\necho "global $*"\n' > "${BATS_TEST_TMPDIR}/bin/cache-clean.js"
  chmod +x "${BATS_TEST_TMPDIR}/bin/cache-clean.js"

  run mage_cmd_watch
  [ "$output" = "global --watch" ]
}

@test "does not report a stopped watcher as missing" {
  function env_local_watch_global() { return 130; }

  run mage_cmd_watch
  [[ "$output" != *"not found"* ]]
}

@test "errors without any cache-clean" {
  use_stub_bins

  run mage_cmd_watch
  [ "$status" -eq 1 ]
  [[ "$output" == *"mage add mage-os/magento-cache-clean --dev"* ]]
}
