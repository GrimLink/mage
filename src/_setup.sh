function mage_setup() {
  # If a project name is provided as an argument, change into that directory.
  # If no argument is provided, assume we are already in the project directory.
  if [[ -n "$1" ]]; then
    if [[ -d "$1" ]]; then
      cd "$1"
    else
      echo "Error: Directory '$1' not found."
      exit 1
    fi
  fi

  # Now that we are in the correct directory, check if it's a Magento project.
  if [ ! -e "composer.json" ]; then
    echo "Error: This does not look like a Magento project directory ('composer.json' is missing)."
    exit 1
  fi

  # Set the name based on the current directory.
  local name=$(basename "$(pwd)")

  # Default config
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

  # Setup db, if not using warden
  if [[ $WARDEN == 0 ]]; then
    if command -v mysql &> /dev/null; then
      echo "Setting up database..."
      mysql -uroot -proot -e "DROP DATABASE IF EXISTS \`${db_name}\`;"
      mysql -uroot -proot -e "CREATE DATABASE \`${db_name}\`;"
    else
      echo "mysql not found!"
      echo "Make sure to create a database before running 'mage setup' again"
      exit 1
    fi
  fi

  # Setup Certificate
  if [[ $VALET == 1 ]]; then
    echo "Securing with Valet..."
    valet secure $name
  fi

  if [[ $WARDEN == 1 ]]; then
    echo "Signing certificate with Warden..."
    warden sign-certificate $name.test
  fi

  echo "Running Magento setup install..."
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
    --session-save-redis-host="${session_redis_host}" \
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
  $MAGENTO_CLI config:set general/store_information/name $name &> /dev/null
  $MAGENTO_CLI config:set admin/usage/enabled 0 &> /dev/null
  $MAGENTO_CLI config:set admin/security/session_lifetime 86400 &> /dev/null
  $MAGENTO_CLI config:set admin/security/password_lifetime "" &> /dev/null
  $MAGENTO_CLI config:set admin/security/password_is_forced 0 &> /dev/null

  $MAGENTO_CLI deploy:mode:set developer

  echo "Disabling 2FA"
  if grep -q 'Magento_AdminAdobeImsTwoFactorAuth' app/etc/config.php;
  then
    $MAGENTO_CLI module:disable Magento_AdminAdobeImsTwoFactorAuth
  fi
  $MAGENTO_CLI module:disable Magento_TwoFactorAuth

  # Prepare Multi Stores when using Valet
  if [[ $VALET == 1 ]]; then
    {
      echo -e '<?php declare(strict_types=1);\n\nreturn ['
      mage_add_valet_store "$name" "default"
      mage_add_valet_store "store-2" "default2" true
      echo '];'
    } > .valet-env.php
  fi

  # Cleanup root sample files
  mage_cleanup_sample_files
}

function mage_getting_started() {
  local name=$1
  echo -e "$name is ready!"
  echo -e "Enter your Magento project directory using ${BLUE}cd ./${name}${RESET}"
  echo -e "Open your Magento project, using ${BLUE}mage open${RESET} or ${BLUE}mage open admin${RESET}"
}
