function mage_purge() {
  case "$1" in
    "opensearch")
      mage_clear_opensearch
      return
      ;;
    "redis")
      mage_clear_redis
      return
      ;;
    "varnish")
      mage_clear_varnish
      return
      ;;
    "sample")
      mage_cleanup_sample_files
      return
      ;;
  esac

  local cleantasks=(
    'generated/metadata/*'
    'generated/code/*'
    'pub/static/*'
    'var/cache/*'
    'var/composer_home/*'
    'var/page_cache/*'
    'var/view_preprocessed/*'
  );

  for i in "${cleantasks[@]}"; do
    $PURGE_CLI ${i} &
    echo -e " [${GREEN}✓${RESET}] ${i}"
  done

  mage_clear_redis
  mage_clear_varnish
}

function mage_clear_redis() {
  if command -v $REDIS_CLI >/dev/null 2>&1; then
    $REDIS_CLI flushall > /dev/null 2>&1
    echo -e " [${GREEN}✓${RESET}] Redis caches flushed"
  fi
}

function mage_clear_varnish() {
  if command -v $VARNISH_CLI >/dev/null 2>&1; then
    $VARNISH_CLI 'ban req.url ~ .' > /dev/null 2>&1
    echo -e " [${GREEN}✓${RESET}] Varnish caches flushed"
  fi
}

function mage_clear_opensearch() {
  local host=$($MAGENTO_CLI config:show catalog/search/opensearch_server_hostname)
  local port=$($MAGENTO_CLI config:show catalog/search/opensearch_server_port)
  local prefix=$($MAGENTO_CLI config:show catalog/search/opensearch_index_prefix)

  # Fallback to defaults if config is empty
  host=${host:-localhost}
  port=${port:-9200}

  if [[ -z "$prefix" ]]; then
    echo -e " [${RED}✗${RESET}] Could not determine OpenSearch index prefix"
    return 1
  fi

  if [[ $WARDEN == 1 ]]; then
    warden env exec -T opensearch curl -s -X DELETE "localhost:9200/${prefix}_*" > /dev/null
  else
    curl -s -X DELETE "${host}:${port}/${prefix}_*" > /dev/null
  fi

  echo -e " [${GREEN}✓${RESET}] OpenSearch indices with prefix '${prefix}_' cleared"
}
