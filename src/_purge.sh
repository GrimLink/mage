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

# Flush only the Redis databases this project uses.
# A 'flushall' would clear every database on the server, which on a shared
# Redis takes the cache and the sessions of every other project with it.
function mage_clear_redis() {
  if ! command -v $REDIS_CLI >/dev/null 2>&1; then
    return
  fi

  if [[ $WARDEN == 1 ]]; then
    # The Redis container belongs to this project alone
    $REDIS_CLI flushall > /dev/null 2>&1
    echo -e " [${GREEN}✓${RESET}] Redis caches flushed"
    return
  fi

  local config="$(get_mage_redis_config)"

  if [[ -z "$config" ]]; then
    echo -e " [${YELLOW}-${RESET}] Redis is not used for cache or sessions, skipping"
    return
  fi

  local host port cache_db page_db session_db
  read -r host port cache_db page_db session_db <<< "$config"

  local db
  for db in "$cache_db" "$page_db" "$session_db"; do
    [[ "$db" == "-" ]] && continue
    $REDIS_CLI -h "$host" -p "$port" -n "$db" flushdb > /dev/null 2>&1
  done

  echo -e " [${GREEN}✓${RESET}] Redis caches flushed on ${host}:${port}"
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
