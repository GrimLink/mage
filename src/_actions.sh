case "${@}" in
"-v" | "--version")
  mage_version
  ;;

"-h" | "--help")
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
  $MAGENTO_CLI theme:change Hyva/default
  $MAGENTO_CLI cache:flush
  ;;

"set baldr")
  $MAGENTO_CLI theme:change Siteation/baldr
  $MAGENTO_CLI cache:flush
  ;;

"config dev")
  $MAGENTO_CLI config:set dev/static/sign 0
  $MAGENTO_CLI deploy:mode:set developer
  ;;

"config admin:captcha")
  $MAGENTO_CLI security:recaptcha:disable-for-user-login
  $MAGENTO_CLI security:recaptcha:disable-for-user-forgot-password
  ;;

"config admin:session")
  echo "Setting session lifetime 86400"
  $MAGENTO_CLI config:set admin/security/session_lifetime 86400
  echo "Setting admin password lifetime ∞"
  $MAGENTO_CLI config:set admin/security/password_lifetime ""
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
