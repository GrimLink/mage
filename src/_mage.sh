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
  STORE=${2:-1}
  STORE_URL=""
  ADMIN_PATH=""

  # Prefetch admin URL data for open steps
  if [[ "$STORE" == "admin" ]]; then
    ADMIN_PATH=$(grep frontName app/etc/env.php | tail -1 | cut -d '>' -f2 | cut -d '"' -f2 | cut -d "'" -f2)
  fi

  # Fetch the store url
  if [[ -n "$MAGERUN_CLI" ]]; then
    if [[ "$STORE" == "admin" ]]; then
      STORE_URL=$($MAGERUN_CLI sys:store:config:base-url:list --format csv | grep 1 -m 1 | head -1 | cut -d ',' -f3)
    else
      STORE_URL=$($MAGERUN_CLI sys:store:config:base-url:list --format csv | grep $STORE | cut -d ',' -f3)
    fi
  else
    STORE_URL=$(get_mage_base_uri)
  fi

  if [[ -z "$STORE_URL" ]]; then
    echo "Could not find url for store $STORE"
  else
    echo -e "Opening: ${STORE_URL}${ADMIN_PATH}"
    $OPEN_CLI ${STORE_URL}${ADMIN_PATH}
  fi
  ;;

"watch")
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
  ;;

"browser-sync")
  # TODO: add option to use your own storeview
  STORE_URL=$(get_mage_base_uri)
  # TODO: add option to watch another folder?
  FILES_TO_WATCH="app/**/*.phtml, app/**/*.xml, app/**/*.css, app/**/*.js"

  if [[ -z "$STORE_URL" ]]; then
    echo "Could not find url for store $STORE"
  else
    npx browser-sync start --proxy ${STORE_URL} --https --files $FILES_TO_WATCH
  fi
  ;;

"reindex")
  $MAGENTO_CLI indexer:reindex && $MAGENTO_CLI cache:flush
  ;;

"purge"*)
  CLEANTASKS=(
    'generated/metadata/*'
    'generated/code/*'
    'pub/static/*'
    'var/cache/*'
    'var/composer_home/*'
    'var/page_cache/*'
    'var/view_preprocessed/*'
  );
  PURGE_CMD="rm -rf"

  if [[ $WARDEN == 1 ]]; then
    # Run removal within environment, so that changes are in effect immediately.
    # Changes will get synced back to host on MacOS.
    PURGE_CMD="warden env exec -T php-fpm rm -rf"
  fi;

  for i in "${CLEANTASKS[@]}"; do
    $PURGE_CMD ${i} &
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
  read -p "Email (${GITEMAIL}) or: " USEREMAIL
  read -p "Firstname (${GITNAME}) or: " USERFIRST
  read -p "Lastname (admin) or: " USERLAST
  read -p "User name (${ADMINNAME}) or: " USERNAME
  read -sp "Password (${ADMINPASS}) or: " USERPASS

  $MAGENTO_CLI admin:user:create \
    --admin-user="${USERNAME:-$ADMINNAME}" \
    --admin-password="${USERPASS:-$ADMINPASS}" \
    --admin-email="${USEREMAIL:-$GITEMAIL}" \
    --admin-firstname="${USERFIRST:-$GITNAME}" \
    --admin-lastname="${USERLAST:-"admin"}"
  ;;

"new customer")
  if [[ -n "$MAGERUN_CLI" ]]; then
    $MAGERUN_CLI customer:create
  else
    echo $NO_MAGERUN_MSG
  fi
  ;;

"new theme")
  new_mage_theme
  ;;

"new module")
  new_mage_module
  ;;

"new i18n"* | "new translate"*)
  SRC=${3:-.}

  if [[ ! -f "$SRC/registration.php" ]]; then
    echo "This does not look like a Magento 2 module or theme"
    read -p "Are you sure if you want to continue? [y/N] "
    echo ""
    if [[ $REPLY =~ ^[yY]|[yY][eE][sS]$ ]]; then
      echo "Running '$MAGENTO_CLI i18n:collect-phrases' in '$SRC'"
    else
      exit 1
    fi;
  fi

  mkdir -p $SRC/i18n
  $MAGENTO_CLI i18n:collect-phrases $SRC -o $SRC/i18n/temp.csv
  sed -i '' -e 's/^\([^"].*\),\([^"].*\)$/"\1","\2"/' $SRC/i18n/temp.csv
  sort -o $SRC/i18n/en_US.csv $SRC/i18n/temp.csv
  rm $SRC/i18n/temp.csv
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
  DEPLOY_MODE="developer"
  IS_MODE_PROD=0
  ADMIN_SESSION_LIFETIME=86400 # 24h in seconds
  ADMIN_PASSWORD_LIFETIME=0

  if [[ $3 == "production" ]] || [[ $3 == "prod" ]]; then
    DEPLOY_MODE="production --skip-compilation"
    IS_MODE_PROD=1
    ADMIN_SESSION_LIFETIME=43200 # 12h in seconds
    ADMIN_PASSWORD_LIFETIME=90 # days
    echo "Also make sure to run 'mage build' or 'bin/magento setup:static-content:deploy', when running production mode"
  else
    rm -rf generated/metadata/*
    rm -rf generated/code/*
  fi

  $MAGENTO_CLI config:set -q dev/static/sign $IS_MODE_PROD
  $MAGENTO_CLI config:set -q admin/captcha/enable $IS_MODE_PROD
  $MAGENTO_CLI config:set -q admin/security/session_lifetime $ADMIN_SESSION_LIFETIME
  $MAGENTO_CLI config:set -q admin/security/password_lifetime $ADMIN_PASSWORD_LIFETIME
  $MAGENTO_CLI config:set -q admin/security/password_is_forced $IS_MODE_PROD
  $MAGENTO_CLI deploy:mode:set $DEPLOY_MODE
  ;;

"set maintenance"*)
  ALLOWED_IPS=${@:2}

  ;;

"build"*)
  # Initialize variables with default values
  LANGS="en_US nl_NL"
  JOBS=4
  FORCE=""
  DEFAULT_ARGS="$LANGS $JOBS"
  ARGS=${@:2}

  # If language is not found in ARGS add the default
  if [[ $ARG != *_* ]]; then
    ARGS="$LANGS $ARGS"
  fi

  # If Jobs is not found in ARGS add the default
  if [[ "$ARGS" != *"-j"* ]] || [[ "$ARGS" != *"--jobs"* ]]; then
    ARGS="$ARGS -j $JOBS"
  fi

  # If force is found in ARGS add it to both adminhtml and frontend
  if [[ "$ARGS" == *"-f"* ]] || [[ "$ARGS" == *"--force"* ]]; then
    FORCE="-f"
  fi

  # Deploy static content
  $MAGENTO_CLI setup:static-content:deploy -a adminhtml en_US ${FORCE} &&
  $MAGENTO_CLI setup:static-content:deploy -a frontend ${ARGS:-$DEFAULT_ARGS}
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
