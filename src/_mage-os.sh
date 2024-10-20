function convert_to_mage_os() {
  if composer show magento/product-community-edition > /dev/null 2>&1; then
    echo "This is not a Magento Community instalation" && exit 1;
  fi

  if composer show mage-os/product-community-edition > /dev/null 2>&1; then
    echo "Mage-OS already installed!" && exit 1;
  fi

  echo "Consider removing any composer replaces, before starting";
  echo "Consider removing any 3de party moduels that could impact the conversion";
  read -rsn1 -p "When ready, press any key to continue";
  echo "";

  # Setup
  composer config repositories.0 composer https://repo.mage-os.org/
  composer require mage-os/product-community-edition --no-update
  composer remove magento/product-community-edition magento/composer-dependency-version-audit-plugin magento/composer-root-update-plugin --no-update
  composer remove sebastian/comparator --dev --no-update # remove if present

  composer config allow-plugins.'mage-os/*' true
  rm -rf vendor

  # Install
  composer update --no-plugins --with-all-dependencies
  mage purge # Cleanup caches
  mage s:up
}
