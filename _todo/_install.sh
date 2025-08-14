function mage_install() {
  local name="$1"
  local default_version="2.4.8"
  local default_edition="community"

  if [[ -z "$name" ]]; then
    echo "The Magento install requires a name!" && exit
  fi

  if [ -e "$name/composer.json" ]; then
    echo -e "$name already exists, aborting.." && exit
  fi

  echo "What Magento edition do want to use?"
  echo "Options: community, enterprise, mage-os"
  read -p "Edition (community): " edition
  if [[ -z "$edition" ]]; then edition="$default_edition"; fi

  # See versions at https://github.com/mage-os/mageos-magento2
  if [[ $edition == "mage-os" ]]; then
    local default_version="^1.1"
  fi

  # See versions at https://experienceleague.adobe.com/docs/commerce-operations/release/versions.html
  echo "What Magento version do want to install?"
  echo "  - empty = latest"
  echo "  Or use your own Magento2 version"
  read -p "Version ($default_version): " version
  if [[ -z "$version" ]]; then version="$default_version"; fi

  if [[ $edition == "mage-os" ]]; then
    echo "Using $edition $version"
  else
    echo "Using Magento $edition $version"
  fi

  echo "Setting up Magento 2 composer"
  if [[ $edition == "mage-os" ]]; then
    $COMPOSER_CLI create-project \
      --no-install \
      --stability dev \
      --prefer-source \
      --repository-url=https://repo.mage-os.org/ mage-os/project-community-edition=$version $name
  else
    $COMPOSER_CLI create-project \
      --no-install \
      --stability dev \
      --prefer-source \
      --repository-url=https://repo.magento.com/ magento/project-$edition-edition=$version $name
  fi

  cd $name

  echo "Adjusting composer settings to allow dev packages"
  $COMPOSER_CLI config minimum-stability dev
  $COMPOSER_CLI config prefer-stable true
  $COMPOSER_CLI config allow-plugins.cweagans/composer-patches true

  echo "Setting up local composer folder"
  mkdir -p package-source
  $COMPOSER_CLI config repositories.local-packages path package-source/*/*

  echo "Setting up default plugins"
  $COMPOSER_CLI require --no-update cweagans/composer-patches yireo/magento2-theme-commands community-engineering/language-nl_nl
  $COMPOSER_CLI require --no-update --dev avstudnitz/scopehint2 spatie/ray

  echo "Running installation.. Enjoy a cup of coffee in the meantime"
  $COMPOSER_CLI install
}
