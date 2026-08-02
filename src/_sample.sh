function mage_add_sample() {
  local mversion="$1"

  if [[ -z "$mversion" ]]; then
    local pkg_name=""
    if grep -q 'magento/product-community-edition' composer.json; then
      pkg_name='magento/product-community-edition'
    elif grep -q 'magento/product-enterprise-edition' composer.json; then
      pkg_name='magento/product-enterprise-edition'
    elif grep -q 'mage-os/project-community-edition' composer.json; then
      pkg_name='mage-os/project-community-edition'
    else
      echo "Could not determine Magento version from composer.json."
      exit 1
    fi

    mversion=$(get_composer_pkg_version $pkg_name)
    if [[ -z "$mversion" ]]; then
      echo "Could not determine Magento version from composer."
      exit 1
    fi
  fi

  local sample_dir="$(mage_config_dir)/sampledata"

  # Keep the clones made before the sample data moved to the mage config folder
  if [[ -d "$HOME/.magento-sampledata" && ! -d "$sample_dir" ]]; then
    mv "$HOME/.magento-sampledata" "$sample_dir"
  fi

  if [[ ! -d "$sample_dir/$mversion" ]]; then
    git clone -b $mversion git@github.com:magento/magento2-sample-data.git $sample_dir/$mversion
  fi

  echo -e "Installing $mversion sample data"
  # Lets make sure these folder exist, to prevent them being made as a symlink
  mkdir -p app/code/Magento
  mkdir -p pub/media/catalog/product
  mkdir -p pub/media/downloadable/files
  mkdir -p pub/media/wysiwyg
  touch README.md
  php -f $sample_dir/$mversion/dev/tools/build-sample-data.php -- --ce-source="$PWD"

  $MAGENTO_CLI setup:upgrade

  # Set theme to Hyva if present
  if is_hyva_installed && is_theme_cli_installed; then
    $MAGENTO_CLI theme:change Hyva/default
  fi

  # Unset default styles from sample data
  $MAGENTO_CLI config:set design/head/includes "" &> /dev/null

  $MAGENTO_CLI indexer:reindex
  $MAGENTO_CLI cache:flush
}
