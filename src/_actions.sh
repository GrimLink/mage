case "${@}" in
"-v" | "--version")
  mage_version
  ;;

"-h" | "--help")
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
  mage_watch
  ;;

"reindex")
  $MAGENTO_CLI indexer:reindex && $MAGENTO_CLI cache:flush
  ;;

"purge")
  mage_purge
  ;;

"new"*)
  echo -e "\n${RED}No ${BOLD}new${RESET}${RED} option given!${RESET}" &&
  help_message
  ;;

"new admin"*)
  mage_new_admin ${@:3}
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
  mage_new_mod "theme" $SRC $DIST
  ;;

"new module"*)
  SRC=${3:-"git@github.com:GrimLink/hyva-module-template.git"}
  DIST=${4:-"package-source"}
  mage_new_mod "module" $SRC $DIST
  ;;

"new i18n"* | "new translate"*)
  mage_new_translate ${@:3}
  ;;

"add"*)
  echo -e "\n${RED}No ${BOLD}add${RESET}${RED} option given!${RESET}" &&
  help_message
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

"set"*)
  echo -e "\n${RED}No ${BOLD}set${RESET}${RED} option given!${RESET}" &&
  help_message
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

"set config"*)
  mage_config ${@:3}
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
