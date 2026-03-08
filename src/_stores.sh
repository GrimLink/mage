function mage_valet_create_store_view() {
  local new_url=$1
  local store_code=$2
  local name=$3

  if [[ $VALET == 1 ]]; then
    echo "Configuring Valet for ${new_url}..."
    if [ ! -f .valet-env.php ]; then
      {
        echo -e '<?php declare(strict_types=1);\n\nreturn ['
        mage_add_valet_store "$name" "default"
        mage_add_valet_store "$new_url" "$store_code"
        echo '];'
      } > .valet-env.php
    else
      awk '/\];/ {next} {print}' .valet-env.php > .valet-env.tmp
      mage_add_valet_store "$new_url" "$store_code" >> .valet-env.tmp
      echo '];' >> .valet-env.tmp
      mv .valet-env.tmp .valet-env.php
    fi

    valet link "$new_url"
    valet secure "$new_url"
  fi
}

function mage_warden_create_store_view() {
  local new_url=$1

  if [[ $WARDEN == 1 ]]; then
    echo "Configuring Warden for ${new_url}..."
    warden sign-certificate "${new_url}.test"

    echo -e "\n${YELLOW}Warden setup requires manual Traefik configuration!${RESET}"
    echo -e "Please update your ${BOLD}.warden/warden-env.yml${RESET} to route ${new_url}.test"
    echo -e "See documentation: ${BLUE}https://docs.warden.dev/environments/mutigen.html#routing-additional-domains${RESET}\n"
  fi
}

function mage_magento_create_store_view() {
  local store_code=$1
  echo "Adding Magento 2 Store View: ${store_code}"
  $PHP_CLI -r "
    use Magento\Framework\App\Bootstrap;
    require 'app/bootstrap.php';
    \$bootstrap = Bootstrap::create(BP, \$_SERVER);
    \$obj = \$bootstrap->getObjectManager();

    \$storeManager = \$obj->get(\Magento\Store\Model\StoreManagerInterface::class);
    \$store = \$obj->create(\Magento\Store\Model\Store::class);
    \$store->load('${store_code}', 'code');
    if (!\$store->getId()) {
        \$group = \$storeManager->getWebsite()->getDefaultGroup();
        \$store->setCode('${store_code}')
            ->setWebsiteId(\$group->getWebsiteId())
            ->setGroupId(\$group->getId())
            ->setName('${store_code}')
            ->setIsActive(1)
            ->save();

        try {
            \$designConfigFactory = \$obj->get(\Magento\Theme\Api\Data\DesignConfigInterfaceFactory::class);
            \$designConfigRepository = \$obj->get(\Magento\Theme\Api\DesignConfigRepositoryInterface::class);
            \$designConfig = \$designConfigFactory->create();
            \$designConfig->setScope('stores');
            \$designConfig->setScopeId(\$store->getId());
            \$designConfigRepository->save(\$designConfig);
        } catch (\Exception \$e) {
            // Ignore error
        }

        echo 'Store view created successfully.';
    } else {
        echo 'Store view already exists.';
    }
  " 2>/dev/null
  echo ""
}

function mage_magento_set_store_view_url() {
  local store_code=$1
  local new_url=$2
  echo "Setting base URL for ${store_code}..."
  $MAGENTO_CLI config:set --scope=stores --scope-code="${store_code}" web/unsecure/base_url "https://${new_url}.test/"
  $MAGENTO_CLI config:set --scope=stores --scope-code="${store_code}" web/secure/base_url "https://${new_url}.test/"
}

function mage_create_store_view() {
  local prefix=$1
  if [[ -z "$prefix" ]]; then
    echo "Please provide a store prefix (e.g. luma)"
    return 1
  fi

  local name=$(basename "$(pwd)")
  local new_url="${prefix}.${name}"
  local store_code="${prefix}"

  mage_valet_create_store_view "$new_url" "$store_code" "$name"
  mage_warden_create_store_view "$new_url"
  mage_magento_create_store_view "$store_code"
  mage_magento_set_store_view_url "$store_code" "$new_url"

  $MAGENTO_CLI indexer:reindex design_config_grid
  $MAGENTO_CLI cache:flush
  echo -e "\nStore view ${store_code} created and configured to use https://${new_url}.test/"
}
