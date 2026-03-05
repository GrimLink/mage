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

  for pkg in "${hyva_themes[@]}"; do
    if [ ! -f "composer.json" ] || ! grep -q "hyva-themes/${pkg}\.git" composer.json; then
      $COMPOSER_CLI config --append ${repo}/${pkg} git ${git_url}:hyva-themes/${pkg}.git
    fi
  done

  if [ ! -f "composer.json" ] || ! grep -q "hyva-themes/hyva-compat/magento2-mollie-theme-bundle\.git" composer.json; then
    $COMPOSER_CLI config --append ${repo}/magento2-mollie-theme-bundle git ${git_url}:hyva-themes/hyva-compat/magento2-mollie-theme-bundle.git
  fi
}

function mage_add_hyva_checkout() {
  echo "Installing Hyva Checkout..."

  if [ -f "composer.json" ] && grep -q -E "hyva-themes/magento2-default-theme(-csp)?\.git" composer.json; then
    local repo="repositories.hyva-themes"
    local git_url="git@gitlab.hyva.io"
    if ! grep -q "hyva-checkout/checkout\.git" composer.json; then
      $COMPOSER_CLI config --append ${repo}/hyva-checkout git ${git_url}:hyva-checkout/checkout.git
    fi
  fi

  $COMPOSER_CLI require hyva-themes/magento2-hyva-checkout
}

function mage_add_hyva_commerce() {
  echo "Installing Hyva Commerce..."

  if [ ! -f "composer.json" ] || ! grep -q -E "hyva-themes/magento2-default-theme(-csp)?\.git" composer.json; then
    $COMPOSER_CLI require hyva-themes/commerce
  else
    local repo="repositories.hyva-themes"
    local git_url="git@gitlab.hyva.io"
    local hyva_commerce_packages=(
      metapackage-commerce
      module-commerce
      module-cms
      module-image-editor
      module-admin-theme
      theme-adminhtml
      module-admin-dashboard
      module-admin-dashboard-google-crux-history-widget
      module-media-optimization
    )

    for pkg in "${hyva_commerce_packages[@]}"; do
      if [ ! -f "composer.json" ] || ! grep -q "hyva-commerce/${pkg}\.git" composer.json; then
        $COMPOSER_CLI config --append ${repo}/${pkg} git ${git_url}:hyva-commerce/${pkg}.git
      fi
    done

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
