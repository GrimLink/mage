function mage_setup() {
  local current_folder=$(basename "$(pwd)")
  local name="${1:-$current_folder}"

  local url="https://${name}.test/"
  local admin_url="${name//-}_admin"

  local db_host="localhost"
  local db_name="${name}"
  local db_user="root"
  local db_password="root"

  local search_host="localhost"
  local session_redis_host="localhost"
  local backend_redis_server="127.0.0.1"
  local page_redis_server="127.0.0.1"

  if [ -e "app/etc/config.php" ]; then
    echo -e "$name has already been setup, aborting.." && exit
  fi

  if [[ $(valet -V | cut -f1,2 -d ' ') == "Laravel Valet" ]]; then
    valet secure $name

    if command -v mysql &> /dev/null; then
      mysql -uroot -proot -e "DROP DATABASE \`${db_name}\`;"
      mysql -uroot -proot -e "CREATE DATABASE \`${db_name}\`;"
    else
      echo "mysql not found!"
      echo "Make sure to create a database before running 'mage setup' again"
      exit
    fi
  fi

  if [[ $WARDEN == 1 ]]; then
    local db_host="db"
    local db_name="magento"
    local db_user="magento"
    local db_password="magento"

    local search_host="opensearch"
    local session_redis_host="redis"
    local backend_redis_server="redis"
    local page_redis_server="redis"
  fi

  $MAGENTO_CLI setup:install \
    --backend-frontname="${admin_url}" \
    --base-url="${url}" \
    --use-rewrites=1 \
    --db-host="${db_host}" \
    --db-name="${db_name}" \
    --db-user="${db_user}" \
    --db-password="${db_password}" \
    --search-engine=opensearch \
    --opensearch-host="${search_host}" \
    --opensearch-port=9200 \
    --opensearch-index-prefix=magento2 \
    --opensearch-enable-auth=0 \
    --opensearch-timeout=15 \
    --session-save=redis \
    --session-save-redis-host="${redis_host}" \
    --session-save-redis-db=2 \
    --session-save-redis-max-concurrency=20 \
    --cache-backend=redis \
    --cache-backend-redis-server="${backend_redis_server}" \
    --cache-backend-redis-db=0 \
    --page-cache=redis \
    --page-cache-redis-server="${page_redis_server}" \
    --page-cache-redis-db=1 \
    --admin-firstname="${ADMINNAME}" \
    --admin-lastname="admin" \
    --admin-email="${ADMINEMAIL}" \
    --admin-user="${ADMINNAME}" \
    --admin-password="${ADMINPASS}"

  echo "Setting default values for Store config"
  $MAGENTO_CLI config:set general/store_information/name $name
  $MAGENTO_CLI config:set admin/usage/enabled 0
  $MAGENTO_CLI config:set admin/security/session_lifetime 86400
  $MAGENTO_CLI config:set admin/security/password_lifetime ""
  $MAGENTO_CLI config:set admin/security/password_is_forced 0

  $MAGENTO_CLI deploy:mode:set developer

  echo "Disabling 2FA"
  if grep -q 'Magento_AdminAdobeImsTwoFactorAuth' app/etc/config.php; then
    $MAGENTO_CLI module:disable Magento_AdminAdobeImsTwoFactorAuth
  fi
  $MAGENTO_CLI module:disable Magento_TwoFactorAuth
}
