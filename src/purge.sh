function mage_purge() {
  CLEANTASKS=(
    'pub/static/*'
    'generated/*'
    'var/cache/*'
    'var/composer_home/*'
    'var/page_cache/*'
    'var/view_preprocessed/*'
  );
  PURGE_CMD="rm -rf"

  if [[ $WARDEN == 1 ]]; then
    # Run removal within environment, so that changes are in effect immediately.
    # Changes will get synced back to host on MacOS.
    PURGE_CMD="warden env exec -T php-fpm rm -rf"
  fi;

  for i in "${CLEANTASKS[@]}"; do
    $PURGE_CMD ${i} &
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
