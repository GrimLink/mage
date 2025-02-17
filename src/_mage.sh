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

"start")
  mage_open_editor
  mage_open_gitclient
  mage open admin
  mage open
  ;;

"open"*)
  mage_open $2;
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

"browser-sync"*)
  store_url=$(get_mage_store_uri ${2:-1})
  files_to_watch="app/**/*.phtml, app/**/*.xml, app/**/*.css, app/**/*.js"

  if [[ -z "$store_url" ]]; then
    echo "Could not find url for store $store"
  else
    npx browser-sync start --proxy ${store_url} --https --files $files_to_watch
  fi
  ;;

"reindex")
  $MAGENTO_CLI indexer:reindex && $MAGENTO_CLI cache:flush
  ;;

"purge")
  mage_purge
  ;;

"new admin")
  read -e -p "Email (${GITEMAIL}) or: " useremail
  read -e -p "Firstname (${GITNAME}) or: " userfirst
  read -e -p "Lastname (admin) or: " userlast
  read -e -p "User name (${ADMINNAME}) or: " username
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

"new patch"*)
  mage_new_patch_file ${3}
  ;;

"new i18n"* | "new translate"*)
  src=${3:-.}

  if [[ ! -f "$src/registration.php" ]]; then
    echo "This does not look like a Magento 2 module or theme"
    read -e -p "Are you sure if you want to continue? [y/N] "
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

"add patch"*)
  mage_add_patch ${@:3}
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

"add baldr")
  composer config repositories.siteation/magento2-theme-baldr git git@github.com:Siteation/magento2-theme-baldr.git
  composer require siteation/magento2-theme-baldr
  ;;

"set theme"*)
  if composer show yireo/magento2-theme-commands > /dev/null 2>&1; then
    $MAGENTO_CLI theme:change $3
    $MAGENTO_CLI cache:flush;
  else
    echo "yireo/magento2-theme-commands is not installed."
  fi
  ;;

"set hyva")
  mage set theme Hyva/default
  ;;

"set baldr")
  mage set theme Siteation/baldr
  ;;

"set mage-os")
  convert_to_mage_os
  ;;

"set mode"*)
  deploy_mode="developer"
  is_mode_prod=0
  admin_session_lifetime=86400 # 24h in seconds
  admin_password_lifetime=0

  if [[ $3 == "production" ]] || [[ $3 == "prod" ]]; then
    deploy_mode="production --skip-compilation"
    is_mode_prod=1
    admin_session_lifetime=43200 # 12h in seconds
    admin_password_lifetime=90 # days
    echo "Also make sure to run 'mage build' or 'bin/magento setup:static-content:deploy', when running production mode"
  else
    $PURGE_CLI generated/metadata/*
    $PURGE_CLI generated/code/*
  fi

  $MAGENTO_CLI config:set -q dev/static/sign $is_mode_prod
  $MAGENTO_CLI config:set -q admin/captcha/enable $is_mode_prod
  $MAGENTO_CLI config:set -q admin/security/session_lifetime $admin_session_lifetime
  $MAGENTO_CLI config:set -q admin/security/password_lifetime $admin_password_lifetime
  $MAGENTO_CLI config:set -q admin/security/password_is_forced $is_mode_prod
  $MAGENTO_CLI deploy:mode:set $deploy_mode
  ;;

"set countries"*)
  scope=""
  countries=""

  for option in "${@:3}"; do
    if [[ "$option" =~ ^store: ]]; then
      # Extract argument after 'store:' (remove prefix)
      stripped_option=${option#store:}
      scope="$stripped_option"
    else
      countries="$countries $option"
    fi
  done

  if [[ -z "$countries" ]]; then
    countries="NL,BE,LU,DE"
  fi

  countries="$(mage_lang_format_arguments $countries)"
  country=$(echo "${countries}" | cut -d ',' -f 1 | tr '[:lower:]' '[:upper:]')

  if [[ -n "$scope" ]]; then
    echo "Setting the following countries: $countries for $scope"
    scope="--scope=stores --scope-code=${scope}"
  else
    echo "Setting the following countries: $countries"
    $MAGENTO_CLI config:set -q general/country/allow $countries
  fi

  $MAGENTO_CLI config:set -q $scope general/country/default $country
  $MAGENTO_CLI config:set -q $scope general/country/destinations $countries
  ;;

"set fpc" | "set fpc default")
  $MAGENTO_CLI config:set system/full_page_cache/caching_application 1
  ;;

"set fpc varnish")
  $MAGENTO_CLI config:set system/full_page_cache/caching_application 2
  ;;

"log" | "log debug")
  tail -f -n 4 var/log/debug.log
  ;;

"log exception")
  tail -f -n 8 var/log/exception.log
  ;;

"log system")
  tail -f -n 8 var/log/system.log
  ;;

"outdated")
  $COMPOSER_CLI outdated --direct --no-dev --ignore symfony/finder --ignore symfony/process --format json > composer-outdated.json
  ;;

"build hyva")
  mage_build_hyva
  ;;

"build"*)
  default_args="-j 4"
  args=${@:2}
  $MAGENTO_CLI setup:static-content:deploy ${args:-$default_args}
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
