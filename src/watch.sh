function mage_watch() {
  CACHE_CLI="echo cache-clean not installed ( https://github.com/mage2tv/magento-cache-clean ) 'composer global require mage2tv/magento-cache-clean'"
  if command -v vendor/bin/cache-clean.js &> /dev/null; then
    CACHE_CLI="vendor/bin/cache-clean.js --watch"
  elif command -v cache-clean.js &> /dev/null; then
    CACHE_CLI="cache-clean.js --watch"
  fi

  if [[ $WARDEN == 1 ]]; then
    # NOTE: we need to sadly hard code the path,
    # but lukcy we can since the warden container is always the same
    warden env exec php-fpm /home/www-data/.composer/vendor/bin/cache-clean.js -w
  else
    $CACHE_CLI
  fi
}
