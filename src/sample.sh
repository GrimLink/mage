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

