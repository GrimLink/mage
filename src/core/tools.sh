# Commands used by mage, an environment can override them in its apply hook

MAGENTO_CLI="bin/magento"
PHP_CLI="php"
COMPOSER_CLI="composer"
NODE_CLI="node"
MYSQL_CLI="mysql"
REDIS_CLI="redis-cli"
VARNISH_CLI="varnishadm"
RSYNC_CLI="rsync"
SEARCH_CURL_CLI="curl"
PURGE_CLI="rm -rf"
OPEN_CLI="xdg-open"

if [[ "$OSTYPE" == "darwin"* ]]; then
  OPEN_CLI="open"
fi

# Detected on first use, see set_magerun_cli
MAGERUN_CLI=""
MAGERUN_CHECKED=0

# Detect the magerun2 cli on first use, as the version check is slow
# in a Magento root and most commands never need it
function set_magerun_cli() {
  if [[ -n "$MAGERUN_CLI" ]] || [[ $MAGERUN_CHECKED == 1 ]]; then
    return
  fi

  MAGERUN_CHECKED=1

  if command -v magerun2 &> /dev/null && magerun2 --version &> /dev/null; then
    MAGERUN_CLI="magerun2"
  elif command -v n98-magerun2 &> /dev/null && n98-magerun2 --version &> /dev/null; then
    MAGERUN_CLI="n98-magerun2"
  fi
}

function check_has_magerun() {
  set_magerun_cli

  if [[ -z "$MAGERUN_CLI" ]]; then
    mage_error "Magerun2 is not installed or incompatible with current PHP version"
    exit 1
  fi
}
