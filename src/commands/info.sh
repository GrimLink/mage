# Show the main facts of the project, read from Magento in one boot, --json for json
function mage_cmd_info() {
  local info
  info="$(mage_info_read 2> /dev/null | grep '^INFO:')"

  if [[ -z "$info" ]]; then
    mage_error "Could not read the project info from Magento"
    exit 1
  fi

  local product=""
  local hyva=""
  local mode=""
  local maintenance=""
  local base_url=""
  local admin_url=""
  local database=""
  local search=""
  local redis=""
  local php=""
  local module_count=0
  local key
  local value

  while IFS='=' read -r key value; do
    case "${key#INFO:}" in
      product) product="$value" ;;
      hyva) hyva="$value" ;;
      mode) mode="$value" ;;
      maintenance) maintenance="$value" ;;
      base_url) base_url="$value" ;;
      admin_url) admin_url="$value" ;;
      database) database="$value" ;;
      search) search="$value" ;;
      redis) redis="$value" ;;
      php) php="$value" ;;
      modules) module_count="$value" ;;
    esac
  done <<< "$info"

  local node
  node="$($NODE_CLI --version 2> /dev/null)"
  node="${node#v}"

  if mage_wants_json "$@"; then
    mage_require_jq "The info as json"
    jq -n \
      --arg product "$product" --arg hyva "$hyva" --arg mode "$mode" \
      --arg maintenance "$maintenance" --arg base_url "$base_url" --arg admin_url "$admin_url" \
      --arg database "$database" --arg search "$search" --arg redis "$redis" \
      --arg php "$php" --arg node "$node" --arg modules "$module_count" \
      'def empty_null: if . == "" then null else . end; {
        product: $product, hyva: ($hyva | empty_null), mode: $mode, maintenance: ($maintenance == "1"),
        base_url: $base_url, admin_url: $admin_url, database: $database,
        search: ($search | empty_null), redis: ($redis | empty_null),
        php: $php, node: ($node | empty_null), modules: ($modules | tonumber)
      }'
    return
  fi

  if [[ -n "$hyva" ]]; then
    mage_info "${BOLD}${product}${RESET} (Hyvä ${GREEN}${hyva}${RESET})"
  else
    mage_info "${BOLD}${product}${RESET}"
  fi

  case "$mode" in
    production) mage_info "- Mode: ${GREEN}Production${RESET}" ;;
    developer) mage_info "- Mode: ${YELLOW}Developer${RESET}" ;;
    *) mage_info "- Mode: ${RED}${mode:-Default}, switch to developer or production${RESET}" ;;
  esac

  if [[ "$maintenance" == 1 ]]; then
    mage_info "- Maintenance: ${RED}ON${RESET}"
  else
    mage_info "- Maintenance: ${GREEN}OFF${RESET}"
  fi

  mage_info "- Base url: ${base_url}"
  mage_info "- Admin url: ${admin_url}"
  mage_info "- Database: ${database}"

  if [[ -n "$search" ]]; then
    mage_info "- Search engine: ${search}"
  fi

  if [[ -n "$redis" ]]; then
    mage_info "- Redis: ${redis}"
  fi

  mage_info "- PHP: ${GREEN}${php}${RESET}"

  if [[ -n "$node" ]]; then
    mage_info "- Node: ${GREEN}${node}${RESET}"
  fi

  # Every module adds to each request, so many of them is worth a warning
  if [[ $module_count -lt 50 ]]; then
    mage_info "- Modules: ${GREEN}${module_count}${RESET}"
  elif [[ $module_count -lt 100 ]]; then
    mage_info "- Modules: ${YELLOW}${module_count}${RESET}"
  else
    mage_info "- Modules: ${RED}${module_count}${RESET} (consider removing some for performance)"
  fi
}

# Echo INFO:key=value lines, the marker keeps them apart from any php notices
function mage_info_read() {
  mage_php '
    $meta = $objectManager->get(\Magento\Framework\App\ProductMetadataInterface::class);
    $deployment = $objectManager->get(\Magento\Framework\App\DeploymentConfig::class);
    $config = $objectManager->get(\Magento\Framework\App\Config\ScopeConfigInterface::class);
    $store = $objectManager->get(\Magento\Store\Model\StoreManagerInterface::class)->getDefaultStoreView();

    $modules = array_filter(
        $objectManager->get(\Magento\Framework\Module\ModuleListInterface::class)->getNames(),
        function ($name) { return strpos($name, "Magento_") !== 0 && $name !== "PayPal_Braintree"; }
    );

    $info = [
        "product" => $meta->getName() . " " . $meta->getEdition() . " " . $meta->getVersion(),
        "mode" => $objectManager->get(\Magento\Framework\App\State::class)->getMode(),
        "maintenance" => $objectManager->get(\Magento\Framework\App\MaintenanceMode::class)->isOn() ? 1 : 0,
        "base_url" => $store->getBaseUrl(\Magento\Framework\UrlInterface::URL_TYPE_WEB, true),
        "admin_url" => mageAdminUrl($objectManager),
        "database" => $deployment->get("db/connection/default/dbname"),
        "search" => $config->getValue("catalog/search/engine"),
        "php" => PHP_VERSION,
        "modules" => count($modules),
    ];

    // The Redis the caches and sessions use, and the prefix that keeps a shared Redis apart
    $cache = $deployment->get("cache/frontend/default") ?: [];
    if (stripos($cache["backend"] ?? "", "redis") !== false) {
        $options = $cache["backend_options"] ?? [];
        $pageCache = $deployment->get("cache/frontend/page_cache/backend_options") ?: [];
        $redis = ($options["server"] ?? "127.0.0.1") . ":" . ($options["port"] ?? "6379")
            . ", cache db " . ($options["database"] ?? "0");
        if (isset($pageCache["database"])) {
            $redis .= ", page cache db " . $pageCache["database"];
        }
        if ($deployment->get("session/save") === "redis") {
            $redis .= ", sessions db " . ($deployment->get("session/redis/database") ?? "2");
        }
        if (!empty($cache["id_prefix"])) {
            $redis .= ", prefix " . $cache["id_prefix"];
        }
        $info["redis"] = $redis;
    }

    $hyva = "hyva-themes/magento2-theme-module";
    if (class_exists(\Composer\InstalledVersions::class) && \Composer\InstalledVersions::isInstalled($hyva)) {
        $info["hyva"] = \Composer\InstalledVersions::getPrettyVersion($hyva);
    }

    foreach ($info as $key => $value) {
        echo "INFO:$key=$value" . PHP_EOL;
    }
  '
}
