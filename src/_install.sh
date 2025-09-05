function mage_install() {
  local name="$1"
  local version=""
  local edition=""
  local repository_url=""
  local repository_name=""

  if [[ -z "$name" ]]; then
    echo "The Magento install requires a name!" && exit
  fi

  if [ -e "$name/composer.json" ]; then
    echo -e "$name already exists, aborting.." && exit
  fi

  echo "What Magento edition do you want to use?"
  echo "Options: community, enterprise, mage-os"
  read -p "Edition (community): " edition

  # Set default edition if empty
  if [[ -z "$edition" ]]; then
    edition="community"
  fi

  case "$edition" in
    "community")
      repository_url="https://repo.magento.com/"
      repository_name="magento/project-community-edition"
      ;;
    "enterprise")
      repository_url="https://repo.magento.com/"
      repository_name="magento/project-enterprise-edition"
      ;;
    "mage-os")
      repository_url="https://repo.mage-os.org/"
      repository_name="mage-os/project-community-edition"
      ;;
    *)
      echo "Invalid edition selected. Aborting."
      exit 1
      ;;
  esac

  # See versions at:
  # - https://github.com/mage-os/mageos-magento2
  # - https://experienceleague.adobe.com/docs/commerce-operations/release/versions.html
  read -p "What Magento version do you want to install (empty = latest): " version

  local package_with_version="$repository_name"
  if [[ -n "$version" ]]; then
    package_with_version="${repository_name}=${version}"
  fi

  if [[ -n "$version" ]]; then
    echo -e "Setting up composer for Magento using distro $edition using v$version"
  else
    echo -e "Setting up composer for Magento using distro $edition"
  fi

  if [[ $WARDEN == 1 ]]; then
    cd "$name"
    warden env-init $name magento2
    warden env up
    $COMPOSER_CLI create-project --no-install --stability dev --prefer-source --repository="$repository_url" "$package_with_version" /tmp/magento
    $RSYNC_CLI -a /tmp/magento/ /var/www/html/
  else
    $COMPOSER_CLI create-project --no-install --stability dev --prefer-source --repository="$repository_url" "$package_with_version" "$name"
    cd "$name"
  fi

  echo "Adjusting composer settings to allow dev packages"
  $COMPOSER_CLI config minimum-stability dev
  $COMPOSER_CLI config prefer-stable true
  $COMPOSER_CLI config allow-plugins.cweagans/composer-patches true

  echo "Setting up local composer folder"
  mkdir -p package-source
  $COMPOSER_CLI config repositories.local-packages path "package-source/*/*"

  echo "Setting up default plugins"
  $COMPOSER_CLI require --no-update mage-os/theme-adminhtml-m137 cweagans/composer-patches yireo/magento2-theme-commands community-engineering/language-nl_nl
  $COMPOSER_CLI require --no-update --dev avstudnitz/scopehint2 spatie/ray

  echo "Running installation.. Enjoy a cup of coffee in the meantime"
  $COMPOSER_CLI install
}
