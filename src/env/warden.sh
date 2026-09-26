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

# The volumes hold the database and search indices, so removing them is enough
function env_warden_nuke() {
  warden env down -v
}
