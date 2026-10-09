MAGE_ADD_HANDLERS+=("store|Create a store view: [PREFIX] for <prefix>.<your domain>, or a full domain")

# Create a store view in the default store group, with its own base url.
# The environment hook makes the domain reachable, or says how to.
function mage_add_store() {
  local url="$1"

  if [[ -z "$url" ]]; then
    url="$(mage_ask "Store prefix or domain, such as luma or b2b.example.test")" || exit 1
  fi

  if [[ -z "$url" ]]; then
    mage_error "A store prefix or domain is required"
    exit 1
  fi

  local base_url
  base_url="$($MAGENTO_CLI config:show web/secure/base_url 2> /dev/null)"
  if [[ -z "$base_url" ]]; then
    base_url="$($MAGENTO_CLI config:show web/unsecure/base_url 2> /dev/null)"
  fi

  if [[ -z "$base_url" ]]; then
    mage_error "Could not get the base url from the Magento config"
    exit 1
  fi

  local protocol="${base_url%%://*}://"
  local base_domain="${base_url#*://}"
  base_domain="${base_domain%%/*}"

  local domain="$url"
  if [[ "$url" != *.* ]]; then
    domain="${url}.${base_domain}"
  fi

  local code="${domain%%.*}"
  code="$(mage_lower_case "${code//-/_}")"

  if [[ ! "$code" =~ ^[a-z][a-z0-9_]*$ ]]; then
    mage_error "'${code}' is not a valid store code, it should start with a letter and hold letters, numbers and underscores"
    exit 1
  fi

  local store_url="${protocol}${domain}/"

  mage_add_store_view "$code" || exit 1
  $MAGENTO_CLI config:set --scope=stores --scope-code="$code" web/unsecure/base_url "$store_url" &&
    $MAGENTO_CLI config:set --scope=stores --scope-code="$code" web/secure/base_url "$store_url" || exit 1

  env_call add_store "$domain" "$code"

  $MAGENTO_CLI indexer:reindex design_config_grid
  $MAGENTO_CLI cache:clean

  mage_check 0 "Store view ${code} uses ${store_url}"
}

# Magento has no command to create a store view
function mage_add_store_view() {
  mage_php '
    $code = $argv[1];

    $store = $objectManager->create(\Magento\Store\Model\Store::class)->load($code, "code");
    if ($store->getId()) {
        echo "Store view $code already exists" . PHP_EOL;
        return;
    }

    $group = $objectManager->get(\Magento\Store\Model\StoreManagerInterface::class)->getWebsite()->getDefaultGroup();
    $store->setCode($code)
        ->setName($code)
        ->setWebsiteId($group->getWebsiteId())
        ->setGroupId($group->getId())
        ->setIsActive(1)
        ->save();

    // Without a design config the store view is missing from the design grid
    $designConfig = $objectManager->get(\Magento\Theme\Api\Data\DesignConfigInterfaceFactory::class)->create();
    $designConfig->setScope("stores");
    $designConfig->setScopeId($store->getId());
    try {
        $objectManager->get(\Magento\Theme\Api\DesignConfigRepositoryInterface::class)->save($designConfig);
    } catch (\Exception $e) {
    }

    echo "Created store view $code" . PHP_EOL;
  ' "$1"
}
