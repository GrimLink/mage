# DDEV, services run in containers, see https://docs.ddev.com/en/stable/users/quickstart/#magento-2

function env_ddev_available() {
  command -v ddev &> /dev/null
}

# Inside the container ddev is not installed, so mage runs there as local
function env_ddev_detect() {
  env_ddev_available && [[ -f .ddev/config.yaml ]]
}

function env_ddev_apply() {
  MAGENTO_CLI="ddev magento"
  PHP_CLI="ddev php"
  COMPOSER_CLI="ddev composer"
  NODE_CLI="ddev exec node"
  NPM_CLI="ddev npm"
  REDIS_CLI="ddev exec -s redis redis-cli"
  RSYNC_CLI="ddev exec rsync"
  SEARCH_CURL_CLI="ddev exec -s opensearch curl"
  PURGE_CLI="ddev exec rm -rf"

  MAGE_DOMAIN="ddev.site"
  MAGE_DB_HOST="db"
  MAGE_DB_NAME="db"
  MAGE_DB_USER="db"
  MAGE_DB_PASS="db"
  MAGE_SEARCH_HOST="opensearch"
  MAGE_REDIS_HOST="redis"
}

# Create the ddev project with the OpenSearch and Redis add-ons,
# and the composer project inside it. Settings management stays off,
# as the Magento install writes the app/etc/env.php.
function env_ddev_create_project() {
  local name="$1"
  local package="$2"
  local repository="$3"

  mkdir "$name" && cd "$name" || return 1
  ddev config --project-type=magento2 --docroot=pub --upload-dirs=media --disable-settings-management || return 1
  ddev add-on get ddev/ddev-opensearch || return 1
  ddev add-on get ddev/ddev-redis || return 1
  ddev start || return 1

  # ddev creates the project in the project root, so no folder is given
  $COMPOSER_CLI create-project --no-install --stability dev --prefer-source --repository="$repository" "$package"
}

# The database already exists in its container, and ddev provides the certificate
function env_ddev_setup_prepare() {
  return 0
}

# Redis runs per project, so it can be flushed as a whole
function env_ddev_clean_redis() {
  $REDIS_CLI flushall > /dev/null
  mage_check $? "Redis"
}

# Removing the project removes its database and add-on volumes too
function env_ddev_nuke() {
  ddev delete --omit-snapshot --yes
}

function env_ddev_add_store() {
  mage_notice "Add ${1} to additional_fqdns or additional_hostnames in .ddev/config.yaml, run 'ddev restart', and set MAGE_RUN_CODE=${2} with MAGE_RUN_TYPE=store for it"
}
