function mage_purge() {
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

  if command -v $REDIS_CLI >/dev/null 2>&1; then
    $REDIS_CLI flushall > /dev/null 2>&1
    echo -e " [${GREEN}✓${RESET}] Redis caches flushed"
  fi

  if command -v $VARNISH_CLI >/dev/null 2>&1; then
    $VARNISH_CLI 'ban req.url ~ .' > /dev/null 2>&1
    echo -e " [${GREEN}✓${RESET}] Varnish caches flushed"
  fi
}
