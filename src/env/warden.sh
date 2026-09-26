# Warden, services run in containers, see https://github.com/wardenenv/warden

function env_warden_available() {
  command -v warden &> /dev/null
}

# Inside the container warden is not installed, so mage runs there as local
function env_warden_detect() {
  env_warden_available && [[ -f .env ]] && grep -q "^WARDEN_ENV_NAME" .env
}

function env_warden_apply() {
  MAGENTO_CLI="warden env exec php-fpm bin/magento"
  MAGERUN_CLI="warden env exec php-fpm n98-magerun"
  PHP_CLI="warden env exec php-fpm php"
  COMPOSER_CLI="warden env exec php-fpm composer"
  NODE_CLI="warden env exec php-fpm node"
  NPM_CLI="warden env exec php-fpm npm"
  REDIS_CLI="warden env exec redis redis-cli"
  VARNISH_CLI="warden env exec -T varnish varnishadm"
  RSYNC_CLI="warden env exec -T php-fpm rsync"
  SEARCH_CURL_CLI="warden env exec -T opensearch curl"
  # Run removal within the container, so changes are in effect immediately
  PURGE_CLI="warden env exec -T php-fpm rm -rf"

  MAGE_DB_HOST="db"
  MAGE_DB_NAME="magento"
  MAGE_DB_USER="magento"
  MAGE_DB_PASS="magento"
  MAGE_SEARCH_HOST="opensearch"
  MAGE_REDIS_HOST="redis"
}

# Create the warden environment and the composer project inside it.
# Composer creates it in /tmp, as it refuses a folder that is not empty.
function env_warden_create_project() {
  local name="$1"
  local package="$2"
  local repository="$3"

  mkdir "$name" && cd "$name" || return 1
  warden env-init "$name" magento2 || return 1
  warden env up || return 1

  $COMPOSER_CLI create-project --no-install --stability dev --prefer-source --repository="$repository" "$package" /tmp/magento || return 1
  $RSYNC_CLI -a /tmp/magento/ /var/www/html/
}

function env_warden_setup_prepare() {
  mage_info "Signing certificate with Warden..."
  warden sign-certificate "${1}.${MAGE_DOMAIN}"
}

# Redis runs per project, so it can be flushed as a whole
function env_warden_clean_redis() {
  $REDIS_CLI flushall > /dev/null
  mage_check $? "Redis"
}

# The volumes hold the database and search indices, so removing them is enough
function env_warden_nuke() {
  warden env down -v
}

function env_warden_add_store() {
  warden sign-certificate "$1"
  mage_notice "Route ${1} in .warden/warden-env.yml and map it to store ${2} in app/etc/stores.php, see https://docs.warden.dev/configuration/multipledomains.html"
}

# Mailpit is a global Warden service, shared by all environments
function env_warden_open_mail() {
  mage_open_browser "https://webmail.warden.test/"
}

# The global composer folder of the container is always in the same place
function env_warden_watch_cli() {
  local cache_clean="/home/www-data/.composer/vendor/bin/cache-clean.js"

  if warden env exec -T php-fpm test -f "$cache_clean"; then
    echo "warden env exec php-fpm ${cache_clean}"
  fi
}
