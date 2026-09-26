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

  mage_clear_opensearch "$db_name"

  if env_local_mysql -e "DROP DATABASE IF EXISTS \`${db_name}\`;"; then
    mage_check 0 "Database '${db_name}' dropped"
  else
    mage_check 1 "Could not drop database '${db_name}'"
  fi
}
