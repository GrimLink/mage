# Clean only the caches affected by file changes, with the cache-clean of the
# project, or a global one. Further arguments go to cache-clean.
function mage_cmd_watch() {
  local cache_clean=""

  if [[ -f vendor/bin/cache-clean.js ]]; then
    cache_clean="$NODE_CLI vendor/bin/cache-clean.js"
  else
    cache_clean="$(env_call watch_cli)"
  fi

  if [[ -z "$cache_clean" ]]; then
    mage_error "cache-clean.js not found, add it with 'mage add mage-os/magento-cache-clean --dev'"
    exit 1
  fi

  $cache_clean --watch "$@"
}
