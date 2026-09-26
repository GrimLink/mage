# Clean only the caches affected by file changes, with the cache-clean of the
# project, or a global one. Further arguments go to cache-clean.
function mage_cmd_watch() {
  if [[ -f vendor/bin/cache-clean.js ]]; then
    $NODE_CLI vendor/bin/cache-clean.js --watch "$@"
    return
  fi

  # The hooks return 127 when there is no global cache-clean, any other status is from the watcher
  env_call watch_global "$@"
  if [[ $? == 127 ]]; then
    mage_error "cache-clean.js not found, add it with 'mage add mage-os/magento-cache-clean --dev'"
    exit 1
  fi
}
