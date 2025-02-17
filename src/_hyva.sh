function mage_add_hyva() {
  echo "Installing Hyva theme..."
  echo "Make sure you have and license key or access to the gitlab env"
  echo "else cancel with Ctrl+C"
  echo ""
  read -e -p "Is this a production setup (use license)? [N/y] "
  echo ""
  if [[ $REPLY =~ ^[yY]|[yY][eE][sS]$ ]]; then
    read -e -p "License key: " hyva_key && echo ""
    read -e -p "Packagist url: " hyva_url && echo ""

    $COMPOSER_CLI config --auth http-basic.hyva-themes.repo.packagist.com token $hyva_key
    $COMPOSER_CLI config repositories.private-packagist composer https://hyva-themes.repo.packagist.com/$hyva_url/
    $COMPOSER_CLI require hyva-themes/magento2-default-theme
  else
    local hyva_repos=(
      'hyva-themes/magento2-theme-module'
      'hyva-themes/magento2-reset-theme'
      'hyva-themes/magento2-email-module'
      'hyva-themes/magento2-order-cancellation-webapi'
      'hyva-themes/magento2-default-theme'
      'hyva-themes/magento2-cms-tailwind-jit'
      'hyva-themes/magento2-compat-module-fallback'
      'hyva-themes/magento2-theme-fallback'
      'hyva-themes/magento2-luma-checkout'
    );

    for i in "${hyva_repos[@]}"; do
      $COMPOSER_CLI config repositories.${i} git git@gitlab.hyva.io:${i}.git
    done

    $COMPOSER_CLI config repositories.hyva-themes/magento2-graphql-tokens git git@github.com:hyva-themes/magento2-graphql-tokens.git
    $COMPOSER_CLI require hyva-themes/magento2-luma-checkout --prefer-source
    $COMPOSER_CLI require hyva-themes/magento2-default-theme --prefer-source
  fi

  $MAGENTO_CLI config:set customer/captcha/enable 0
  $MAGENTO_CLI s:up

  if $COMPOSER_CLI show yireo/magento2-theme-commands >/dev/null 2>&1; then
    $MAGENTO_CLI theme:change Hyva/default
  fi

  echo "Done!"
  echo "Navigate to the Content > Design > Configuration admin section to activate the theme"
  echo ""
  echo "For more see the docs -> https://docs.hyva.io/hyva-themes/getting-started/ "
}

function mage_add_checkout() {
  echo "Installing Hyva checkout..."
  echo "Make sure you have and license key or access to the gitlab env"
  echo "else cancel with Ctrl+C"
  echo ""
  read -e -p "Is this a production setup (use license)? [N/y] "
  echo ""
  if [[ $REPLY =~ ^[yY]|[yY][eE][sS]$ ]]; then
    read -e -p "License key: " hyva_key && echo ""
    read -e -p "Packagist url: " HYVA_URL && echo ""

    $COMPOSER_CLI config --auth http-basic.hyva-themes.repo.packagist.com token $hyva_key
    $COMPOSER_CLI config repositories.private-packagist composer https://hyva-themes.repo.packagist.com/$HYVA_URL/
    $COMPOSER_CLI require hyva-themes/magento2-hyva-checkout
  else
    $COMPOSER_CLI config repositories.hyva-themes/hyva-checkout git git@gitlab.hyva.io:hyva-checkout/checkout.git
    $COMPOSER_CLI require hyva-themes/magento2-hyva-checkout --prefer-source
  fi
}

function mage_build_hyva() {
  if [ ! -d vendor/hyva-themes/magento2-default-theme/web/tailwind/node_modules ]; then
    $NPM_CLI --prefix vendor/hyva-themes/magento2-default-theme/web/tailwind install;
  fi
  $NPM_CLI --prefix vendor/hyva-themes/magento2-default-theme/web/tailwind run build;
}
