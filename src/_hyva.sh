function mage_add_hyva() {
  echo "Make sure you have and license key or access to the gitlab env"
  echo "else cancel with Ctrl+C"
  echo ""
  read -e -p "Is this a production setup (use license)? [N/y] "
  echo ""
  if [[ $REPLY =~ ^[yY]|[yY][eE][sS]$ ]]; then
    if [ ! -f "auth.json" ]; then
      read -e -p "No license found, add license? [Y/n] "
      echo ""
      if [[ ! $REPLY =~ ^[nN]|[nN][oO]$ ]]; then
        read -e -p "License key: " hyva_key && echo ""
        read -e -p "Packagist url: " hyva_url && echo ""
        $COMPOSER_CLI config --auth http-basic.hyva-themes.repo.packagist.com token $hyva_key
        $COMPOSER_CLI config repositories.private-packagist composer https://hyva-themes.repo.packagist.com/$hyva_url/
        echo "Installing Hyva theme..."
        $COMPOSER_CLI require hyva-themes/magento2-default-theme
      else
        echo "Installing Hyva theme..."
        $COMPOSER_CLI require hyva-themes/magento2-default-theme
      fi
    else
      echo "Installing Hyva theme..."
      $COMPOSER_CLI require hyva-themes/magento2-default-theme
    fi
  else
    mage_add_hyva_dev
  fi;

  $MAGENTO_CLI config:set customer/captcha/enable 0

  if $COMPOSER_CLI show yireo/magento2-theme-commands >/dev/null 2>&1; then
    $MAGENTO_CLI theme:change Hyva/default
  fi

  echo "Done!"
  echo "Navigate to the Content > Design > Configuration admin section to activate the theme"
  echo ""
  echo "For more see the docs -> https://docs.hyva.io/hyva-themes/getting-started/ "
}

function mage_add_hyva_dev() {
  echo "Adding repositories..."

  # Core Module Deps
  $COMPOSER_CLI config repositories.hyva-themes/magento2-mollie-theme-bundle git git@gitlab.hyva.io:hyva-themes/hyva-compat/magento2-mollie-theme-bundle.git

  # Core Theme Deps
  $COMPOSER_CLI config repositories.hyva-themes/magento2-reset-theme git git@gitlab.hyva.io:hyva-themes/magento2-reset-theme.git
  $COMPOSER_CLI config repositories.hyva-themes/magento2-theme-module git git@gitlab.hyva.io:hyva-themes/magento2-theme-module.git
  $COMPOSER_CLI config repositories.hyva-themes/magento2-email-module git git@gitlab.hyva.io:hyva-themes/magento2-email-module.git
  # magento2-graphql-tokens Found on: https://packagist.org/packages/hyva-themes/magento2-graphql-tokens
  # magento2-graphql-view-model Found on: https://packagist.org/packages/hyva-themes/magento2-graphql-view-model
  $COMPOSER_CLI config repositories.hyva-themes/magento2-order-cancellation-webapi git git@gitlab.hyva.io:hyva-themes/magento2-order-cancellation-webapi.git
  $COMPOSER_CLI config repositories.hyva-themes/magento2-default-theme git git@gitlab.hyva.io:hyva-themes/magento2-default-theme.git

  # Extra Deps
  $COMPOSER_CLI config repositories.hyva-themes/magento2-default-theme-csp git git@gitlab.hyva.io:hyva-themes/magento2-default-theme-csp.git
  $COMPOSER_CLI config repositories.hyva-themes/magento2-cms-tailwind-jit git git@gitlab.hyva.io:hyva-themes/magento2-cms-tailwind-jit.git
  $COMPOSER_CLI config repositories.hyva-themes/magento2-compat-module-fallback git git@gitlab.hyva.io:hyva-themes/magento2-compat-module-fallback.git
  $COMPOSER_CLI config repositories.hyva-themes/magento2-theme-fallback git git@gitlab.hyva.io:hyva-themes/magento2-theme-fallback.git
  $COMPOSER_CLI config repositories.hyva-themes/magento2-luma-checkout git git@gitlab.hyva.io:hyva-themes/magento2-luma-checkout.git

  # Checkout Deps
  $COMPOSER_CLI config repositories.hyva-themes/hyva-checkout git git@gitlab.hyva.io:hyva-checkout/checkout.git

  # Commerce Deps
  $COMPOSER_CLI config repositories.hyva-themes/commerce git git@gitlab.hyva.io:hyva-commerce/metapackage-commerce.git
  $COMPOSER_CLI config repositories.hyva-themes/commerce-module-commerce git git@gitlab.hyva.io:hyva-commerce/module-commerce.git
  $COMPOSER_CLI config repositories.hyva-themes/commerce-module-cms git git@gitlab.hyva.io:hyva-commerce/module-cms.git

  echo "Installing Hyva theme..."
  $COMPOSER_CLI require hyva-themes/magento2-default-theme --prefer-source
}

function mage_add_hyva_checkout() {
  echo "Installing Hyva Checkout..."
  $COMPOSER_CLI require hyva-themes/magento2-hyva-checkout
}

function mage_add_hyva_commerce() {
  echo "Installing Hyva Commerce..."
  $COMPOSER_CLI require hyva-themes/commerce
}

function mage_build_hyva() {
  if [ ! -d vendor/hyva-themes/magento2-default-theme/web/tailwind/node_modules ]; then
    $NPM_CLI --prefix vendor/hyva-themes/magento2-default-theme/web/tailwind install;
  fi
  $NPM_CLI --prefix vendor/hyva-themes/magento2-default-theme/web/tailwind run build;
}
