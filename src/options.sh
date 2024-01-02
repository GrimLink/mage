case "${@}" in
"version" | "-v" | "--version")
  mage_version
  ;;
  
"help")
  mage_version
  mage_help
  ;;

"self-update")
  mage_self_update
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
  mage_open
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

"reindex")
  $MAGENTO_CLI indexer:reindex && $MAGENTO_CLI cache:flush
  ;;

"purge"*)
  CLEANTASKS=(
    'pub/static/*'
    'generated/*'
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

"new admin"*)
  if [[ "$3" == "--yes" ]] || [[ "$3" == "-y" ]]; then
    SKIP="true"
  fi

  if [[ $SKIP == "false" ]]; then
    read -p "Email (${GITEMAIL}) or: " USEREMAIL
    read -p "Firstname (${GITNAME}) or: " USERFIRST
    read -p "Lastname (admin) or: " USERLAST
    read -p "User name (${ADMINNAME}) or: " USERNAME
    read -sp "Password (${ADMINPASS}) or: " USERPASS
  fi

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

"new theme"*)
  SRC=${3:-"vendor/hyva-themes/magento2-default-theme"}
  DIST=${4:-"app/design/frontend"}
  new_mage_mod "theme" $SRC $DIST
  ;;

"new module"*)
  SRC=${3:-"git@github.com:GrimLink/hyva-module-template.git"}
  DIST=${4:-"package-source"}
  new_mage_mod "module" $SRC $DIST
  ;;

"new translate"* | "new i18n"*)
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

"new"*)
  echo -e "\n${RED}No ${BOLD}new${RESET}${RED} option given!${RESET}" && help_message
  ;;

"add sample")
  read -p "What is your Magento base version (sample: 2.4): " MVERSION && echo ""
  if [[ -z "$MVERSION" ]]; then echo "The Magento 2 version is empty, aborting.." && exit 1; fi

  if [[ ! -d "$HOME/.magento-sampledata/$MVERSION" ]]; then
    git clone -b $MVERSION git@github.com:magento/magento2-sample-data.git $HOME/.magento-sampledata/$MVERSION
  fi
  
  echo -e "Installing $MVERSION sample data"
  # Lets make sure these folder exist, to prevent them being made as a symlink
  mkdir -p app/code/Magento
  mkdir -p pub/media/catalog/product
  mkdir -p pub/media/downloadable/files
  mkdir -p pub/media/wysiwyg
  touch README.md
  php -f $HOME/.magento-sampledata/$MVERSION/dev/tools/build-sample-data.php -- --ce-source="$PWD"
  $MAGENTO_CLI setup:upgrade

  # Set theme to Hyva if present
  if composer show hyva-themes/magento2-default-theme >/dev/null 2>&1; then
    if composer show yireo/magento2-theme-commands >/dev/null 2>&1; then
      $MAGENTO_CLI theme:change Hyva/default
    fi
  fi
  ;;

"add hyva")
  echo "Installing Hyva theme..."
  echo "Make sure you have and license key or access to the gitlab env"
  echo "else cancel with Ctrl+C"
  echo ""
  read -p "Is this a production setup (use license)? [N/y] "
  echo ""
  if [[ $REPLY =~ ^[yY]|[yY][eE][sS]$ ]]; then
    read -p "License key: " HYVA_KEY && echo ""
    read -p "Packagist url: " HYVA_URL && echo ""

    $COMPOSER_CLI config --auth http-basic.hyva-themes.repo.packagist.com token $HYVA_KEY
    $COMPOSER_CLI config repositories.private-packagist composer https://hyva-themes.repo.packagist.com/$HYVA_URL/
    $COMPOSER_CLI require hyva-themes/magento2-default-theme
  else
    HYVA_REPOS=(
      'hyva-themes/magento2-theme-module'
      'hyva-themes/magento2-reset-theme'
      'hyva-themes/magento2-email-module'
      'hyva-themes/magento2-default-theme'
      'hyva-themes/magento2-compat-module-fallback'
      'hyva-themes/magento2-theme-fallback'
      'hyva-themes/magento2-luma-checkout'
    );

    for i in "${HYVA_REPOS[@]}"; do
      $COMPOSER_CLI config repositories.${i} git git@gitlab.hyva.io:${i}.git
    done

    $COMPOSER_CLI config repositories.hyva-themes/magento2-graphql-tokens git git@github.com:hyva-themes/magento2-graphql-tokens.git
    $COMPOSER_CLI require hyva-themes/magento2-luma-checkout --prefer-source
    $COMPOSER_CLI require hyva-themes/magento2-default-theme --prefer-source
  fi

  $MAGENTO_CLI config:set customer/captcha/enable 0
  $MAGENTO_CLI s:up

  if composer show yireo/magento2-theme-commands >/dev/null 2>&1; then
    $MAGENTO_CLI theme:change Hyva/default
  fi

  echo "Done!"
  echo "Navigate to the Content > Design > Configuration admin section to activate the theme"
  echo ""
  echo "For more see the docs -> https://docs.hyva.io/hyva-themes/getting-started/ "
  ;;

"add checkout")
  echo "Installing Hyva checkout..."
  echo "Make sure you have and license key or access to the gitlab env"
  echo "else cancel with Ctrl+C"
  echo ""
  read -p "Is this a production setup (use license)? [N/y] "
  echo ""
  if [[ $REPLY =~ ^[yY]|[yY][eE][sS]$ ]]; then
    read -p "License key: " HYVA_KEY && echo ""
    read -p "Packagist url: " HYVA_URL && echo ""

    $COMPOSER_CLI config --auth http-basic.hyva-themes.repo.packagist.com token $HYVA_KEY
    $COMPOSER_CLI config repositories.private-packagist composer https://hyva-themes.repo.packagist.com/$HYVA_URL/
    $COMPOSER_CLI require hyva-themes/magento2-hyva-checkout
  else
    $COMPOSER_CLI config repositories.hyva-themes/hyva-checkout git git@gitlab.hyva.io:hyva-checkout/checkout.git
    $COMPOSER_CLI require hyva-themes/magento2-hyva-checkout --prefer-source
  fi
  ;;

"add"*)
  echo -e "\n${RED}No ${BOLD}add${RESET}${RED} option given!${RESET}" && help_message
  ;;

"set theme"*)
  $MAGENTO_CLI theme:change $3
  $MAGENTO_CLI cache:flush;
  ;;

"set hyva")
  $MAGENTO_CLI theme:change Hyva/default
  $MAGENTO_CLI cache:flush
  ;;

"set baldr")
  $MAGENTO_CLI theme:change Siteation/baldr
  $MAGENTO_CLI cache:flush
  ;;

"config" | "set config")
  mage_config
  ;;

"config "* | "set config "*)
  mage_config ${@:2}
  ;;

"set"*)
  echo -e "\n${RED}No ${BOLD}set${RESET}${RED} option given!${RESET}" && help_message
  ;;

"composer"*)
  $COMPOSER_CLI ${@:2}
  ;;

"install "* | "i "*)
  if [[ -n ${@:2} ]]; then
    $COMPOSER_CLI require ${@:2}
  else 
    echo "No packages where specified!"
  fi
  ;;

"install" | "i")
  $COMPOSER_CLI install
  ;;

"update "* | "up "*)
  if [[ -n ${@:2} ]]; then
    $COMPOSER_CLI update ${@:2}
  else
    echo "No packages where specified!"
  fi
  ;;

"remove "* | "rm "*)
  if [[ -n ${@:2} ]]; then
    $COMPOSER_CLI remove ${@:2}
  else
    echo "No packages where specified!"
  fi
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