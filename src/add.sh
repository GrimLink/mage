function mage_add_sample() {
  read -p "What is your Magento base version (sample: 2.4): " MVERSION && echo ""
  if [[ -z "$MVERSION" ]]; then echo "The Magento 2 version is empty, aborting.." && exit 1; fi

  if [[ ! -d "$HOME/.magento-sampledata/$MVERSION" ]]; then
    git clone -b $MVERSION git@github.com:magento/magento2-sample-data.git $HOME/.magento-sampledata/$MVERSION
  fi

  echo -e "Installing $MVERSION sample data"
  # Lets make sure these folder exist, to prevent them being made as a symlink
  mkdir -p app/code/Magento
  mkdir -p pub/media/catalog/product
  mkdir -p pub/media/downloadable/files
  mkdir -p pub/media/wysiwyg
  touch README.md
  php -f $HOME/.magento-sampledata/$MVERSION/dev/tools/build-sample-data.php -- --ce-source="$PWD"
  $MAGENTO_CLI setup:upgrade

  # Set theme to Hyva if present
  if composer show hyva-themes/magento2-default-theme >/dev/null 2>&1; then
    if composer show yireo/magento2-theme-commands >/dev/null 2>&1; then
      $MAGENTO_CLI theme:change Hyva/default
    fi
  fi
}

function mage_add_hyva() {
  echo "Installing Hyva theme..."
  echo "Make sure you have and license key or access to the gitlab env"
  echo "else cancel with Ctrl+C"
  echo ""
  read -p "Is this a production setup (use license)? [N/y] "
  echo ""
  if [[ $REPLY =~ ^[yY]|[yY][eE][sS]$ ]]; then
    read -p "License key: " HYVA_KEY && echo ""
    read -p "Packagist url: " HYVA_URL && echo ""

    $COMPOSER_CLI config --auth http-basic.hyva-themes.repo.packagist.com token $HYVA_KEY
    $COMPOSER_CLI config repositories.private-packagist composer https://hyva-themes.repo.packagist.com/$HYVA_URL/
    $COMPOSER_CLI require hyva-themes/magento2-default-theme
  else
    HYVA_REPOS=(
      'hyva-themes/magento2-theme-module'
      'hyva-themes/magento2-reset-theme'
      'hyva-themes/magento2-email-module'
      'hyva-themes/magento2-default-theme'
      'hyva-themes/magento2-compat-module-fallback'
      'hyva-themes/magento2-theme-fallback'
      'hyva-themes/magento2-luma-checkout'
    );

    for i in "${HYVA_REPOS[@]}"; do
      $COMPOSER_CLI config repositories.${i} git git@gitlab.hyva.io:${i}.git
    done

    $COMPOSER_CLI config repositories.hyva-themes/magento2-graphql-tokens git git@github.com:hyva-themes/magento2-graphql-tokens.git
    $COMPOSER_CLI require hyva-themes/magento2-luma-checkout --prefer-source
    $COMPOSER_CLI require hyva-themes/magento2-default-theme --prefer-source
  fi

  $MAGENTO_CLI config:set customer/captcha/enable 0
  $MAGENTO_CLI s:up

  if composer show yireo/magento2-theme-commands >/dev/null 2>&1; then
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
  read -p "Is this a production setup (use license)? [N/y] "
  echo ""
  if [[ $REPLY =~ ^[yY]|[yY][eE][sS]$ ]]; then
    read -p "License key: " HYVA_KEY && echo ""
    read -p "Packagist url: " HYVA_URL && echo ""

    $COMPOSER_CLI config --auth http-basic.hyva-themes.repo.packagist.com token $HYVA_KEY
    $COMPOSER_CLI config repositories.private-packagist composer https://hyva-themes.repo.packagist.com/$HYVA_URL/
    $COMPOSER_CLI require hyva-themes/magento2-hyva-checkout
  else
    $COMPOSER_CLI config repositories.hyva-themes/hyva-checkout git git@gitlab.hyva.io:hyva-checkout/checkout.git
    $COMPOSER_CLI require hyva-themes/magento2-hyva-checkout --prefer-source
  fi
}
