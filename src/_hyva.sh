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
  else
    mage_setup_dev
  fi

  echo "Installing Hyva theme..."
  $COMPOSER_CLI require hyva-themes/magento2-theme-module
  $COMPOSER_CLI require hyva-themes/magento2-default-theme
  $MAGENTO_CLI config:set customer/captcha/enable 0 &> /dev/null
}

function mage_setup_dev() {
  echo "Adding repositories..."

  local repo="repositories.hyva-themes"
  local git_url="git@gitlab.hyva.io"
  local hyva_themes=(
    magento2-base-layout-reset
    magento2-cms-tailwind-jit
    magento2-compat-module-fallback
    magento2-default-theme
    magento2-default-theme-csp
    magento2-email-module
    magento2-luma-checkout
    magento2-order-cancellation-webapi
    magento2-reset-theme
    magento2-theme-fallback
    magento2-theme-module
  )

  # Core Theme Deps
  for pkg in "${hyva_themes[@]}"; do
    $COMPOSER_CLI config --append ${repo}/${pkg} git ${git_url}:hyva-themes/${pkg}.git
  done

  $COMPOSER_CLI config --append ${repo}/magento2-mollie-theme-bundle git ${git_url}:hyva-themes/hyva-compat/magento2-mollie-theme-bundle.git

  # Checkout Deps
  $COMPOSER_CLI config --append ${repo}/hyva-checkout git ${git_url}:hyva-checkout/checkout.git

  # Commerce Deps
  $COMPOSER_CLI config --append ${repo}/commerce git ${git_url}:hyva-commerce/metapackage-commerce.git
  $COMPOSER_CLI config --append ${repo}/commerce-module-commerce git ${git_url}:hyva-commerce/module-commerce.git
  $COMPOSER_CLI config --append ${repo}/commerce-module-cms git ${git_url}:hyva-commerce/module-cms.git
  $COMPOSER_CLI config --append ${repo}/commerce-module-image-editor git ${git_url}:hyva-commerce/module-image-editor.git
  $COMPOSER_CLI config --append ${repo}/commerce-module-admin-theme git ${git_url}:hyva-commerce/module-admin-theme.git
  $COMPOSER_CLI config --append ${repo}/commerce-theme-adminhtml git ${git_url}:hyva-commerce/theme-adminhtml.git
  $COMPOSER_CLI config --append ${repo}/commerce-module-admin-dashboard git ${git_url}:hyva-commerce/module-admin-dashboard.git

  # Dev Deps
  $COMPOSER_CLI config --append ${repo}/commerce-module-admin-dashboard-google-crux-history-widget git ${git_url}:hyva-commerce/module-admin-dashboard-google-crux-history-widget.git
  $COMPOSER_CLI config --append ${repo}/commerce-module-media-optimization git ${git_url}:hyva-commerce/module-media-optimization.git
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
  local path="vendor/hyva-themes/magento2-default-theme"

  if [ -d vendor/hyva-themes/magento2-default-theme-csp ]; then
    path="vendor/hyva-themes/magento2-default-theme-csp"
  fi

  if [ -d $path ]; then
      if [ ! -d ${path}/web/tailwind/node_modules ]; then
      $NPM_CLI --prefix ${path}/web/tailwind i;
    fi
    $NPM_CLI --prefix ${path}/web/tailwind run build;
  fi
}
