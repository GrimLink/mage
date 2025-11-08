case "${@}" in
"version")
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
  mage_info
  ;;

"modules")
  get_mage_modules
  ;;

"create" | "install")
  echo "No name was given for the magento project, aborting.."
  ;;

"create "*)
  mage_install $2
  mage_setup

  read -p "Add sample data? [y/N] "
  echo ""
  if [[ $REPLY =~ ^[yY]|[yY][eE][sS]$ ]]; then
    mage_add_sample
  fi

  mage_getting_started $2
  ;;

"install "*)
  mage_install $2
  ;;

"setup")
  mage_setup
  mage_getting_started $(basename "$(pwd)")
  ;;

"setup "*)
  mage_setup $2
  mage_getting_started $2
  ;;

"stores")
  check_has_magerun
  $MAGERUN_CLI sys:store:config:base-url:list --format txt
  ;;

"start")
  mage_open_editor
  mage_open_gitclient
  mage_open admin
  mage_open
  ;;

"open "*)
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
    # but lucky we can since the warden container is always the same
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
  check_has_magerun
  $MAGERUN_CLI customer:create
  ;;

"new theme")
  mage_new_theme
  ;;

"new module")
  mage_new_module
  ;;

"new patch"*)
  mage_new_patch ${@:3}
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
  echo "Make sure you have and license key or access to the gitlab env"
  read -rsn1 -p "When ready, press any key to continue";
  echo "";

  read -p "Is this a production setup (use license)? [N/y]" HYVA_PRODUCTION && echo ""
  read -p "Add Checkout? [Y/n]" HYVA_ADD_CHECKOUT && echo ""
  read -p "Add Commerce? [Y/n]" HYVA_ADD_COMMERCE && echo ""

  if [[ -z "$HYVA_PRODUCTION" ]]; then HYVA_PRODUCTION="No"; fi
  if [[ -z "$HYVA_ADD_CHECKOUT" ]]; then HYVA_ADD_CHECKOUT="Yes"; fi
  if [[ -z "$HYVA_ADD_COMMERCE" ]]; then HYVA_ADD_COMMERCE="Yes"; fi

  mage_add_hyva $HYVA_PRODUCTION

  if [[ ! $HYVA_ADD_CHECKOUT =~ ^[nN]|[nN][oO]$ ]]; then
    echo ""
    mage_add_hyva_checkout
  fi

  if [[ ! $HYVA_ADD_COMMERCE =~ ^[nN]|[nN][oO]$ ]]; then
    echo ""
    mage_add_hyva_commerce $HYVA_PRODUCTION
  fi

  $MAGENTO_CLI s:up

  if $COMPOSER_CLI show yireo/magento2-theme-commands >/dev/null 2>&1; then
    $MAGENTO_CLI theme:change Hyva/default
  fi

  mage_build_hyva

  echo "Done!"
  echo "For more information, see the docs -> https://docs.hyva.io/hyva-themes/getting-started/ "
  ;;

"add checkout" | "add hyva checkout")
  mage_add_hyva_checkout
  ;;

"add hyva commerce")
  mage_add_hyva_commerce
  ;;

"add baldr")
  $COMPOSER_CLI config repositories.siteation/magento2-theme-baldr git git@github.com:Siteation/magento2-theme-baldr.git
  $COMPOSER_CLI require siteation/magento2-theme-baldr
  ;;

"set mage-os")
  convert_to_mage_os
  ;;

"set theme"*)
  SET_THEME_NAME=$3

  if [[ $SET_THEME_NAME == "hyva" ]]; then
    SET_THEME_NAME="Hyva/default"
  fi

  if [[ $SET_THEME_NAME == "baldr" ]]; then
    SET_THEME_NAME="Siteation/baldr"
  fi

  if [[ $SET_THEME_NAME == "breeze" ]]; then
    SET_THEME_NAME="Swissup/breeze-blank"
  fi

  if $COMPOSER_CLI show yireo/magento2-theme-commands > /dev/null 2>&1; then
    $MAGENTO_CLI theme:change $SET_THEME_NAME
    $MAGENTO_CLI cache:flush;
  else
    echo "yireo/magento2-theme-commands is not installed."
  fi
  ;;

"set fpc" | "set fpc "*)
  MAGENTO_FPC=$([[ $3 == "varnish" ]] && echo 2 || echo 1)
  $MAGENTO_CLI config:set system/full_page_cache/caching_application $MAGENTO_FPC &> /dev/null
  ;;

"set csp")
  check_has_magerun
  $MAGERUN_CLI config:env:set system/default/csp/policies/storefront/scripts/inline 0
  $MAGERUN_CLI config:env:set system/default/csp/policies/storefront/scripts/eval 0
  $MAGERUN_CLI config:env:set system/default/csp/mode/storefront/report_only 0
  $MAGENTO_CLI app:config:import
  ;;

"log" | "log "*)
  log_file="${2:-debug}"

  case "$log_file" in
    "clear")
      find var/log/ -name "*.log" -delete
      ;;
    "show")
      ls -1 var/log/
      ;;
    *)
      if [ -f "var/log/${log_file}.log" ]; then
        tail -f -n 6 "var/log/${log_file}.log"
      else
        echo "Error: Log file not found: var/log/${log_file}.log"
        echo "Available logs:"
        ls -1 var/log/
      fi
      ;;
  esac
  ;;

"outdated")
  $COMPOSER_CLI outdated --direct --no-dev --ignore symfony/finder --ignore symfony/process --format json > composer-outdated.json
  ;;

"build hyva")
  mage_build_hyva
  ;;

"build" | "build "*)
  default_args="-j 4"
  args=${@:2}
  $MAGENTO_CLI setup:static-content:deploy ${args:-$default_args}
  ;;

"version "* | "help "* | "self-update "*)
  mage_help
  echo -e "\n${BOLD}${RED}No arguments are expected for '$1'!${RESET}"
  ;;

"run" | "run "*)
  check_has_magerun
  $MAGERUN_CLI "${@:2}"
  ;;

"enable" *)
  if [[ "$2" == *"_"* ]]; then
    $MAGENTO_CLI module:enable $2
  else
    $MAGENTO_CLI module:enable $($MAGENTO_CLI module:status | grep -E $2)
  fi
  ;;

*)
  $MAGENTO_CLI "$@"
  ;;
esac
