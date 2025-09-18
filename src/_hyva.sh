function mage_add_hyva() {
  local use_hyva_production=$1

  if [[ $use_hyva_production =~ ^[yY]|[yY][eE][sS]$ ]]; then
    if [ ! -f "auth.json" ] && [ ! -f "$HOME/.composer/auth.json" ]; then
      read -e -p "No license found, add license? [Y/n] "
      echo ""
      if [[ ! $REPLY =~ ^[nN]|[nN][oO]$ ]]; then
        read -e -p "License key: " hyva_key && echo ""
        $COMPOSER_CLI config --auth http-basic.hyva-themes.repo.packagist.com token $hyva_key
      fi
    fi
    read -e -p "Packagist domain (e.g. acme): " hyva_url && echo ""
    if [[ -z $hyva_url ]]; then hyva_url="hyva-themes"; fi
    $COMPOSER_CLI config repositories.private-packagist composer https://hyva-themes.repo.packagist.com/$hyva_url/

    echo "Installing Hyva theme..."
    $COMPOSER_CLI require hyva-themes/magento2-default-theme
  else
    mage_add_hyva_dev
  fi;

  $MAGENTO_CLI config:set customer/captcha/enable 0 &> /dev/null
}

function mage_add_hyva_dev() {
  echo "Adding repositories..."

  # Core Theme Deps
  $COMPOSER_CLI config repositories.hyva-themes/magento2-reset-theme git git@gitlab.hyva.io:hyva-themes/magento2-reset-theme.git
  $COMPOSER_CLI config repositories.hyva-themes/magento2-theme-module git git@gitlab.hyva.io:hyva-themes/magento2-theme-module.git
  $COMPOSER_CLI config repositories.hyva-themes/magento2-mollie-theme-bundle git git@gitlab.hyva.io:hyva-themes/hyva-compat/magento2-mollie-theme-bundle.git
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
  $COMPOSER_CLI config repositories.hyva-themes/commerce-module-image-editor git git@gitlab.hyva.io:hyva-commerce/module-image-editor.git
  $COMPOSER_CLI config repositories.hyva-themes/commerce-module-admin-theme git git@gitlab.hyva.io:hyva-commerce/module-admin-theme.git
  $COMPOSER_CLI config repositories.hyva-themes/commerce-theme-adminhtml git git@gitlab.hyva.io:hyva-commerce/theme-adminhtml.git
  $COMPOSER_CLI config repositories.hyva-themes/commerce-module-admin-dashboard git git@gitlab.hyva.io:hyva-commerce/module-admin-dashboard.git
  # Dev Deps
  $COMPOSER_CLI config repositories.hyva-themes/commerce-module-admin-dashboard-google-crux-history-widget git git@gitlab.hyva.io:hyva-commerce/module-admin-dashboard-google-crux-history-widget.git
  $COMPOSER_CLI config repositories.hyva-themes/commerce-module-media-optimization git git@gitlab.hyva.io:hyva-commerce/module-media-optimization.git

  echo "Installing Hyva theme..."
  $COMPOSER_CLI require hyva-themes/magento2-default-theme --prefer-source
}

function mage_add_hyva_checkout() {
  echo "Installing Hyva Checkout..."
  $COMPOSER_CLI require hyva-themes/magento2-hyva-checkout
}

function mage_add_hyva_commerce() {
  local use_hyva_production=$1

  echo "Installing Hyva Commerce..."
  if [[ $use_hyva_production =~ ^[yY]|[yY][eE][sS]$ ]]; then
    $COMPOSER_CLI require hyva-themes/commerce
  else
    $COMPOSER_CLI require hyva-themes/commerce-module-cms
    $COMPOSER_CLI require hyva-themes/commerce-module-image-editor
    $COMPOSER_CLI require hyva-themes/commerce-theme-adminhtml
    $COMPOSER_CLI require hyva-themes/commerce-module-admin-dashboard
  fi
}

function mage_build_hyva() {
  if [ ! -d vendor/hyva-themes/magento2-default-theme/web/tailwind/node_modules ]; then
    $NPM_CLI --prefix vendor/hyva-themes/magento2-default-theme/web/tailwind install;
  fi
  $NPM_CLI --prefix vendor/hyva-themes/magento2-default-theme/web/tailwind run build;
}
