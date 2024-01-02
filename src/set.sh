function mage_config() {
  CONFIG_RUN_CACHE="false"
  CONFIG_RUN_ADMIN_SESSION="false"
  CONFIG_RUN_DISABLE_SECURITY="false"
  CONFIG_RUN_DEV_MODE="false"
  FLAGS="${@}"

  if [[ "$FLAGS" == *"--cache"* || "$FLAGS" =~ ^"-"([^ ]*)"c".* ]]; then
    CONFIG_RUN_CACHE="true"
  fi
  if [[ "$FLAGS" == *"--admin-session"* || "$FLAGS" =~ ^"-"([^ ]*)"a".* ]]; then
    CONFIG_RUN_ADMIN_SESSION="true"
  fi
  if [[ "$FLAGS" == *"--disable-security"* || "$FLAGS" =~ ^"-"([^ ]*)"s".* ]]; then
    CONFIG_RUN_DISABLE_SECURITY="true"
  fi
  if [[ "$FLAGS" == *"--dev-mode"* || "$FLAGS" =~ ^"-"([^ ]*)"d".* ]]; then
    CONFIG_RUN_DEV_MODE="true"
  fi

  if [[ -z "$FLAGS" ]]; then
    CONFIG_RUN_CACHE="true";
    CONFIG_RUN_ADMIN_SESSION="true"
  fi

  if [[ "$CONFIG_RUN_CACHE" == "true" ]]; then
    echo "Disabling frontend caches"
    $MAGENTO_CLI cache:disable layout block_html full_page
  fi
  
  if [[ "$CONFIG_RUN_ADMIN_SESSION" == "true" ]]; then
    echo "Setting session lifetime 86400"
    $MAGENTO_CLI config:set admin/security/session_lifetime 86400
    echo "Setting admin password lifetime ∞"
    $MAGENTO_CLI config:set admin/security/password_lifetime ""
  fi
  if [[ "$CONFIG_RUN_DISABLE_SECURITY" == "true" ]]; then
    $MAGENTO_CLI security:recaptcha:disable-for-user-login
    $MAGENTO_CLI security:recaptcha:disable-for-user-forgot-password
  fi

  if [[ "$CONFIG_RUN_DEV_MODE" == true ]]; then
    $MAGENTO_CLI config:set dev/static/sign 0
    $MAGENTO_CLI deploy:mode:set developer
    echo "Removing Crons, make sure you're not running this on a live environment!"
    read -p "Are your sure? [y/N] "
    echo ""
    if [[ $REPLY =~ ^[yY]|[yY][eE][sS]$ ]]; then
      $MAGENTO_CLI cron:remove
    fi;
  fi
}