# The local environment is the fallback for every hook,
# the defaults it runs with are set in core/tools.sh and core/config.sh

function env_local_available() {
  return 0
}

function env_local_detect() {
  return 0
}

function env_local_apply() {
  return 0
}

# Run mysql with the MAGE_DB_* credentials
function env_local_mysql() {
  MYSQL_PWD="$MAGE_DB_PASS" $MYSQL_CLI -h"$MAGE_DB_HOST" -u"$MAGE_DB_USER" "$@"
}

# Create the composer project in a new folder, and move into it
function env_local_create_project() {
  local name="$1"
  local package="$2"
  local repository="$3"

  $COMPOSER_CLI create-project --no-install --stability dev --prefer-source --repository="$repository" "$package" "$name" || return 1
  cd "$name" || return 1
}

# Prepare the services before the Magento install, a new empty database
function env_local_setup_prepare() {
  local db_name="$2"

  if ! command -v $MYSQL_CLI &> /dev/null; then
    mage_error "mysql not found! Create the database '${db_name}' before running 'mage setup' again"
    return 1
  fi

  mage_info "Setting up database '${db_name}'..."
  env_local_mysql -e "DROP DATABASE IF EXISTS \`${db_name}\`;" &&
    env_local_mysql -e "CREATE DATABASE \`${db_name}\`;"
}

function env_local_nuke() {
  local db_name="$2"

  mage_clean_opensearch "$db_name"
  env_local_clean_redis

  if env_local_mysql -e "DROP DATABASE IF EXISTS \`${db_name}\`;"; then
    mage_check 0 "Database '${db_name}' dropped"
  else
    mage_check 1 "Could not drop database '${db_name}'"
  fi
}

# Delete the cache keys of the project from Redis, by the id prefix of each
# cache in app/etc/env.php, so other projects on the same Redis keep theirs
function env_local_clean_redis() {
  if ! command -v $REDIS_CLI &> /dev/null; then
    mage_check 1 "redis-cli not found, the Redis caches are left as is"
    return 1
  fi

  local cache
  local options
  local prefix
  local host
  local port
  local db

  for cache in default page_cache; do
    options="cache/frontend/${cache}/backend_options"
    prefix="$(mage_env_php "cache/frontend/${cache}/id_prefix")"
    host="$(mage_env_php "${options}/server" || echo "$MAGE_REDIS_HOST")"
    port="$(mage_env_php "${options}/port" || echo 6379)"
    db="$(mage_env_php "${options}/database" || echo 0)"

    if [[ -z "$prefix" ]]; then
      mage_check 1 "Could not determine the Redis prefix of the ${cache} cache"
      continue
    fi

    # Cache keys look like zc:k:<prefix><ID> and their tags like zc:ti:<prefix><TAG>
    $REDIS_CLI -h "$host" -p "$port" -n "$db" --scan --pattern "zc:*:${prefix}*" |
      xargs -n 100 $REDIS_CLI -h "$host" -p "$port" -n "$db" del &> /dev/null

    mage_check 0 "Redis ${cache} cache with prefix '${prefix}'"
  done
}

# The domain of a new store view is up to the web server on your machine
function env_local_add_store() {
  mage_notice "Point ${1} to this project in your web server, and set MAGE_RUN_CODE=${2} with MAGE_RUN_TYPE=store for it"
}

function env_local_open_mail() {
  mage_open_browser "$MAGE_MAIL_URL"
}

# A global cache-clean, from 'composer global require mage-os/magento-cache-clean'
function env_local_watch_global() {
  if ! command -v cache-clean.js &> /dev/null; then
    return 127
  fi

  cache-clean.js --watch "$@"
}
