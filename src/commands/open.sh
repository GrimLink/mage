# Open the default store view, a store view by its code, the admin, or the mail catcher
function mage_cmd_open() {
  local target="$1"

  if [[ "$target" == "mail" ]]; then
    env_call open_mail
    return
  fi

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

  mage_open_browser "$url"
}

# Show the url, and open it when there is an open command, so over ssh the url is still there
function mage_open_browser() {
  mage_info "Opening $1"

  if command -v "${OPEN_CLI%% *}" &> /dev/null; then
    $OPEN_CLI "$1" &> /dev/null
  fi
}

# Ask Magento for the url, so the store and website scopes and the custom admin
# path and url all count. The markers keep the result apart from any php notices.
function mage_open_url() {
  mage_php '
    $storeManager = $objectManager->get(\Magento\Store\Model\StoreManagerInterface::class);
    $target = $argv[1] ?? "";
    $web = \Magento\Framework\UrlInterface::URL_TYPE_WEB;

    if ($target === "admin") {
        echo "URL:" . mageAdminUrl($objectManager) . PHP_EOL;
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
  ' "$1" 2> /dev/null
}
