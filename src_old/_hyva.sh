function mage_add_hyva() {
  read -p "Is this a production setup (use license)? [Y/n] "
  echo ""
  if [[ ! $REPLY =~ ^[nN]|[nN][oO]$ ]]; then
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

    if [ ! -f "composer.json" ] || ! grep -q "https://hyva-themes.repo.packagist.com/$hyva_url/" composer.json; then
      $COMPOSER_CLI config repositories.private-packagist composer https://hyva-themes.repo.packagist.com/$hyva_url/
    fi
  else
    mage_setup_hyva_dev
  fi

  echo "Installing Hyva theme..."
  $COMPOSER_CLI require hyva-themes/magento2-theme-module
  $COMPOSER_CLI require hyva-themes/magento2-default-theme
  $MAGENTO_CLI config:set customer/captcha/enable 0 &> /dev/null
}

function mage_setup_hyva_dev() {
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
    magento2-cms-tailwind-jit
    magento2-cms-tailwind-compiler
  )

  echo "Adding the Hyva packages to $(mage_packages_dir)..."

  for pkg in "${hyva_themes[@]}"; do
    mage_add_global_package "${git_url}:hyva-themes/${pkg}.git" "hyva-themes/${pkg}"
  done

  mage_add_global_package \
    "${git_url}:hyva-themes/hyva-compat/magento2-mollie-theme-bundle.git" \
    "hyva-themes/magento2-mollie-theme-bundle"

  mage_use_global_packages
}

function mage_add_hyva_checkout() {
  echo "Installing Hyva Checkout..."

  if is_using_global_packages; then
    mage_add_global_package "git@gitlab.hyva.io:hyva-checkout/checkout.git" "hyva-checkout/checkout"
  fi

  $COMPOSER_CLI require hyva-themes/magento2-hyva-checkout
}

function mage_add_hyva_commerce() {
  echo "Installing Hyva Commerce..."

  if ! is_using_global_packages; then
    $COMPOSER_CLI require hyva-themes/commerce
  else
    local git_url="git@gitlab.hyva.io"
    local hyva_commerce_packages=(
      metapackage-commerce
      module-commerce
      module-admin-dashboard
      module-admin-dashboard-cms-widgets
      module-admin-dashboard-google-crux-history-widget
      module-cms
      module-cms-ai-translations
      module-cms-google-maps
      module-image-editor
      module-media-optimization
      module-menu-builder
      theme-adminhtml
      module-admin-theme
    )

    echo "Adding the Hyva Commerce packages to $(mage_packages_dir)..."

    for pkg in "${hyva_commerce_packages[@]}"; do
      mage_add_global_package "${git_url}:hyva-commerce/${pkg}.git" "hyva-commerce/${pkg}"
    done

    mage_add_global_package \
      "${git_url}:hyva-themes/commerce-module-admin-dashboard-api.git" \
      "hyva-themes/commerce-module-admin-dashboard-api"

    mage_add_global_package \
      "${git_url}:hyva-commerce/commerce-module-cms-tailwind-jit-bridge.git" \
      "hyva-commerce/commerce-module-cms-tailwind-jit-bridge"

    $COMPOSER_CLI require hyva-themes/commerce-module-cms
    $COMPOSER_CLI require hyva-themes/commerce-module-menu-builder
    $COMPOSER_CLI require hyva-themes/commerce-module-image-editor
    $COMPOSER_CLI require hyva-themes/commerce-module-media-optimization
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
