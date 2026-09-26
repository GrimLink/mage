# Open the default store view, a store view by its code, or with 'admin' the admin
function mage_cmd_open() {
  local target="$1"
  local result
  result="$(mage_open_url "$target")"

  local url
  url="$(grep '^URL:' <<< "$result" | head -n 1)"
  url="${url#URL:}"

  if [[ -z "$url" ]]; then
    local codes
    codes="$(grep '^CODES:' <<< "$result" | head -n 1)"

    if [[ -n "$codes" ]]; then
      mage_error "Unknown store view '${target}', use admin or one of: ${codes#CODES:}"
    else
      mage_error "Could not get the url from Magento"
    fi
    exit 1
  fi

  mage_info "Opening ${url}"

  if command -v "${OPEN_CLI%% *}" &> /dev/null; then
    $OPEN_CLI "$url" &> /dev/null
  fi
}

# Ask Magento for the url, so the store and website scopes and the custom admin
# path and url all count. The markers keep the result apart from any php notices.
function mage_open_url() {
  $PHP_CLI -r '
    require "app/bootstrap.php";
    $objectManager = \Magento\Framework\App\Bootstrap::create(BP, $_SERVER)->getObjectManager();
    $storeManager = $objectManager->get(\Magento\Store\Model\StoreManagerInterface::class);
    $target = $argv[1] ?? "";
    $web = \Magento\Framework\UrlInterface::URL_TYPE_WEB;

    if ($target === "admin") {
        $config = $objectManager->get(\Magento\Framework\App\Config\ScopeConfigInterface::class);
        $base = $config->isSetFlag("admin/url/use_custom")
            ? $config->getValue("admin/url/custom")
            : $storeManager->getStore(0)->getBaseUrl($web, true);
        $frontName = $objectManager->get(\Magento\Backend\App\Area\FrontNameResolver::class)->getFrontName();
        echo "URL:" . rtrim($base, "/") . "/" . $frontName . "/" . PHP_EOL;
        return;
    }

    $stores = $storeManager->getStores(false, true);
    if ($target === "") {
        $store = $storeManager->getDefaultStoreView();
    } elseif (isset($stores[$target])) {
        $store = $stores[$target];
    } else {
        echo "CODES:" . implode(", ", array_keys($stores)) . PHP_EOL;
        return;
    }

    echo "URL:" . $store->getBaseUrl($web, true) . PHP_EOL;
  ' -- "$1" 2> /dev/null
}
