function mage_add_sample() {
  read -e -p "What is your Magento base version (sample: 2.4): " mversion && echo ""
  if [[ -z "$mversion" ]]; then echo "The Magento 2 version is empty, aborting.." && exit 1; fi

  if [[ ! -d "$HOME/.magento-sampledata/$mversion" ]]; then
    git clone -b $mversion git@github.com:magento/magento2-sample-data.git $HOME/.magento-sampledata/$mversion
  fi

  echo -e "Installing $mversion sample data"
  # Lets make sure these folder exist, to prevent them being made as a symlink
  mkdir -p app/code/Magento
  mkdir -p pub/media/catalog/product
  mkdir -p pub/media/downloadable/files
  mkdir -p pub/media/wysiwyg
  touch README.md
  php -f $HOME/.magento-sampledata/$mversion/dev/tools/build-sample-data.php -- --ce-source="$PWD"
  $MAGENTO_CLI setup:upgrade

  # Set theme to Hyva if present
  if $COMPOSER_CLI show hyva-themes/magento2-default-theme >/dev/null 2>&1; then
    if $COMPOSER_CLI show yireo/magento2-theme-commands >/dev/null 2>&1; then
      $MAGENTO_CLI theme:change Hyva/default
    fi

    # Unset default styles from sample data
    $MAGENTO_CLI config:set design/head/includes ""
  fi

  $MAGENTO_CLI indexer:reindex
  $MAGENTO_CLI cache:flush
}
