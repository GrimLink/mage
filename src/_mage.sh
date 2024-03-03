case "${@}" in
"version" | "-v" | "--version")
  mage_version
  ;;

"help")
  mage_version
  mage_help
  ;;

"self-update")
  cd $(dirname "${BASH_SOURCE}") &&
  rm mage &&
  $GET_CLI https://raw.githubusercontent.com/GrimLink/mage/main/mage &&
  chmod +x mage
  ;;

"info")
  $MAGENTO_CLI --version
  echo -e "Base URI: $(get_mage_base_uri)"
  echo -e "Admin URI: $(grep frontName app/etc/env.php | tail -1 | cut -d ">" -f2 | cut -d "'" -f2)"
  echo -e "Database: $(grep dbname app/etc/env.php | tail -1 | cut -d ">" -f2 | cut -d "'" -f2)"
  $MAGENTO_CLI maintenance:status
  $MAGENTO_CLI deploy:mode:show
  if [[ -n "$MAGENTO_CLI config:show catalog/search/engine" ]]; then
    echo -e "Search Engine: $($MAGENTO_CLI config:show catalog/search/engine)"
  fi
  ;;

"stores")
  if [[ -n "$MAGERUN_CLI" ]]; then
    $MAGERUN_CLI sys:store:config:base-url:list --format txt
  else
    echo $NO_MAGERUN_MSG
  fi
  ;;

"open"*)
  store=${2:-1}
  store_url=""
  admin_path=""

  # Prefetch admin URL data for open steps
  if [[ "$store" == "admin" ]]; then
    admin_path=$(grep frontName app/etc/env.php | tail -1 | cut -d '>' -f2 | cut -d '"' -f2 | cut -d "'" -f2)
  fi

  # Fetch the store url
  if [[ -n "$MAGERUN_CLI" ]]; then
    if [[ "$store" == "admin" ]]; then
      store_url=$($MAGERUN_CLI sys:store:config:base-url:list --format csv | grep 1 -m 1 | head -1 | cut -d ',' -f3)
    else
      store_url=$($MAGERUN_CLI sys:store:config:base-url:list --format csv | grep $store | cut -d ',' -f3)
    fi
  else
    store_url=$(get_mage_base_uri)
  fi

  if [[ -z "$store_url" ]]; then
    echo "Could not find url for store $store"
  else
    echo -e "Opening: ${store_url}${admin_path}"
    $OPEN_CLI ${store_url}${admin_path}
  fi
  ;;

"watch")
  cache_cli="echo cache-clean not installed ( https://github.com/mage2tv/magento-cache-clean ) 'composer global require mage2tv/magento-cache-clean'"
  if command -v vendor/bin/cache-clean.js &> /dev/null; then
    cache_cli="vendor/bin/cache-clean.js --watch"
  elif command -v cache-clean.js &> /dev/null; then
    cache_cli="cache-clean.js --watch"
  fi

  if [[ $WARDEN == 1 ]]; then
    # NOTE: we need to sadly hard code the path,
    # but lukcy we can since the warden container is always the same
    warden env exec php-fpm /home/www-data/.composer/vendor/bin/cache-clean.js -w
  else
    $cache_cli
  fi
  ;;

"browser-sync")
  # TODO: add option to use your own storeview
  store_url=$(get_mage_base_uri)
  files_to_watch="app/**/*.phtml, app/**/*.xml, app/**/*.css, app/**/*.js"

  if [[ -z "$store_url" ]]; then
    echo "Could not find url for store"
  else
    npx browser-sync start --proxy ${store_url} --https --files $files_to_watch
  fi
  ;;

"reindex")
  $MAGENTO_CLI indexer:reindex && $MAGENTO_CLI cache:flush
  ;;

"purge"*)
  cleantasks=(
    'generated/metadata/*'
    'generated/code/*'
    'pub/static/*'
    'var/cache/*'
    'var/composer_home/*'
    'var/page_cache/*'
    'var/view_preprocessed/*'
  );
  purge_cmd="rm -rf"

  if [[ $WARDEN == 1 ]]; then
    # Run removal within environment, so that changes are in effect immediately.
    # Changes will get synced back to host on MacOS.
    purge_cmd="warden env exec -T php-fpm rm -rf"
  fi;

  for i in "${cleantasks[@]}"; do
    $purge_cmd ${i} &
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
  ;;

"new admin")
  read -p "Email (${GITEMAIL}) or: " useremail
  read -p "Firstname (${GITNAME}) or: " userfirst
  read -p "Lastname (admin) or: " userlast
  read -p "User name (${ADMINNAME}) or: " username
  read -sp "Password (${ADMINPASS}) or: " userpass

  $MAGENTO_CLI admin:user:create \
    --admin-user="${username:-$ADMINNAME}" \
    --admin-password="${userpass:-$ADMINPASS}" \
    --admin-email="${useremail:-$GITEMAIL}" \
    --admin-firstname="${userfirst:-$GITNAME}" \
    --admin-lastname="${userlast:-"admin"}"
  ;;

"new customer")
  if [[ -n "$MAGERUN_CLI" ]]; then
    $MAGERUN_CLI customer:create
  else
    echo $NO_MAGERUN_MSG
  fi
  ;;

"new theme")
  mage_new_theme
  ;;

"new module")
  mage_new_module
  ;;

"new i18n"* | "new translate"*)
  src=${3:-.}

  if [[ ! -f "$src/registration.php" ]]; then
    echo "This does not look like a Magento 2 module or theme"
    read -p "Are you sure if you want to continue? [y/N] "
    echo ""
    if [[ $REPLY =~ ^[yY]|[yY][eE][sS]$ ]]; then
      echo "Running '$MAGENTO_CLI i18n:collect-phrases' in '$src'"
    else
      exit 1
    fi;
  fi

  mkdir -p $src/i18n
  $MAGENTO_CLI i18n:collect-phrases $src -o $src/i18n/temp.csv
  sed -i '' -e 's/^\([^"].*\),\([^"].*\)$/"\1","\2"/' $src/i18n/temp.csv
  sort -o $src/i18n/en_US.csv $src/i18n/temp.csv
  rm $src/i18n/temp.csv
  ;;

"add sample")
  mage_add_sample
  ;;

"add hyva")
  mage_add_hyva
  ;;

"add checkout")
  mage_add_checkout
  ;;

"set theme"*)
  $MAGENTO_CLI theme:change $3
  $MAGENTO_CLI cache:flush;
  ;;

"set hyva")
  mage set theme Hyva/default
  ;;

"set baldr")
  mage set theme Siteation/baldr
  ;;

"set mode"*)
  deploy_mode="developer"
  is_mode_prod=0
  admin_session_lifetime=86400 # 24h in seconds
  admin_password_lifetime=0
  purge_cmd="rm -rf"

  if [[ $WARDEN == 1 ]]; then
    # Run removal within environment, so that changes are in effect immediately.
    # Changes will get synced back to host on MacOS.
    purge_cmd="warden env exec -T php-fpm rm -rf"
  fi;

  if [[ $3 == "production" ]] || [[ $3 == "prod" ]]; then
    deploy_mode="production --skip-compilation"
    is_mode_prod=1
    admin_session_lifetime=43200 # 12h in seconds
    admin_password_lifetime=90 # days
    echo "Also make sure to run 'mage build' or 'bin/magento setup:static-content:deploy', when running production mode"
  else
    $purge_cmd generated/metadata/*
    $purge_cmd generated/code/*
  fi

  $MAGENTO_CLI config:set -q dev/static/sign $is_mode_prod
  $MAGENTO_CLI config:set -q admin/captcha/enable $is_mode_prod
  $MAGENTO_CLI config:set -q admin/security/session_lifetime $admin_session_lifetime
  $MAGENTO_CLI config:set -q admin/security/password_lifetime $admin_password_lifetime
  $MAGENTO_CLI config:set -q admin/security/password_is_forced $is_mode_prod
  $MAGENTO_CLI deploy:mode:set $deploy_mode
  ;;

"set countries"*)
  default_country="NL"
  default_countries="NL,BE,LU,DE"
  countries="$(mage_lang_format_arguments ${3:-$default_countries})"
  country="${3:-$default_country}"

  $MAGENTO_CLI general/country/default - $country
  $MAGENTO_CLI general/country/allow - $countries
  $MAGENTO_CLI general/country/destinations - $countries
  ;;

"set maintenance"*)
  allowed_ips=${@:2}

  ;;

"log debug")
  tail var/log/debug.log -n -f
  ;;

"log exception")
  tail var/log/exception.log -n -f
  ;;

"log system")
  tail var/log/system.log -n -f
  ;;

"build"*)
  mage_build ${@:2}
  ;;

"run"*)
  if [[ -n "$MAGERUN_CLI" ]]; then
    $MAGERUN_CLI ${@:2}
  else
    echo $NO_MAGERUN_MSG
  fi
  ;;

*)
  $MAGENTO_CLI $@
  ;;
esac
