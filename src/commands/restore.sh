# Replace the database with a backup of 'mage backup', the latest by default,
# unpack its media when there is one, and set it up for this device
function mage_cmd_restore() {
  local file=""
  local media=""
  local arg

  for arg in "$@"; do
    case "$arg" in
      --media) media=1 ;;
      --no-media) media=0 ;;
      -*)
        mage_error "Unknown option '${arg}'"
        exit 1
        ;;
      *) file="$arg" ;;
    esac
  done

  if [[ ! -f app/etc/env.php ]]; then
    mage_error "Magento is not installed on this device, run 'mage setup' first"
    exit 1
  fi

  if [[ -z "$file" ]]; then
    local candidate

    for candidate in "$MAGE_BACKUP_DIR"/*.sql.gz; do
      if [[ -f "$candidate" ]] && { [[ -z "$file" ]] || [[ "$candidate" -nt "$file" ]]; }; then
        file="$candidate"
      fi
    done
  fi

  if [[ -z "$file" ]]; then
    mage_error "No backup found in ${MAGE_BACKUP_DIR}, give the file of 'mage backup'"
    exit 1
  fi

  if [[ ! -f "$file" ]]; then
    mage_error "${file} not found"
    exit 1
  fi

  file="$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"

  local media_file="${file%.sql.gz}-media.tar.gz"

  if [[ $media == 1 ]] && [[ ! -f "$media_file" ]]; then
    mage_error "${media_file} not found"
    exit 1
  fi

  if [[ ! -f "$media_file" ]]; then
    media=0
  elif [[ -z "$media" ]]; then
    media=0

    if mage_confirm "Also unpack $(basename "$media_file") into pub/media?" y; then
      media=1
    fi
  fi

  local name
  name="$(basename "$PWD")"

  mage_warn "This replaces the database of ${PWD} with $(basename "$file")"

  if ! mage_confirm_name "$name"; then
    mage_info "Aborting restore.."
    exit 1
  fi

  mage_env_php_db

  mage_info "Importing the database..."
  env_call restore_db "$file" || exit 1
  mage_check 0 "Database from ${file}"

  if [[ $media == 1 ]]; then
    mage_info "Unpacking the media..."
    tar -xzf "$media_file" -C pub || exit 1
    mage_check 0 "Media from ${media_file}"
  fi

  # Before setup:upgrade, as it checks the search engine
  local url="https://${name}.${MAGE_DOMAIN}/"
  local stores

  stores="$(mage_restore_local_config "$url" | tr -d '\r' | grep '^STORE:')"

  if [[ -z "$stores" ]]; then
    mage_error "Could not point the config to this device"
    exit 1
  fi

  mage_check 0 "Base urls on ${MAGE_DOMAIN}, and the search engine of this device"

  mage_restore_stores "$stores"

  # The cache still holds the config from before the import
  $MAGENTO_CLI cache:clean > /dev/null

  # Modules of this device, such as the dev packages, may not be in the backup yet
  if ! $MAGENTO_CLI setup:db:status &> /dev/null; then
    $MAGENTO_CLI setup:upgrade || exit 1
  fi

  mage_set_store_config
  $MAGENTO_CLI deploy:mode:set developer

  mage_cmd_reindex || exit 1

  # The first store view is the default one
  local main="${stores%%$'\n'*}"
  main="${main#STORE:}"

  mage_info ""
  mage_info "${GREEN}${name} is restored!${RESET}"
  mage_info "Store: ${BLUE}https://${main%% *}/${RESET}"
  mage_notice "The admin users are those of the backup, add your own with 'mage add admin'"
}

# Make the domain of each store view reachable, where a domain shared by
# several store views goes to the first one, the default store view of its store
function mage_restore_stores() {
  local line
  local domain
  local code
  local seen=" "

  while read -r line; do
    domain="${line#STORE:}"
    code="${domain#* }"
    domain="${domain%% *}"

    if [[ -z "$domain" ]] || [[ "$seen" == *" ${domain} "* ]]; then
      continue
    fi

    seen+="${domain} "
    env_call add_store "$domain" "$code"
    mage_check 0 "Store view ${code} uses https://${domain}/"
  done <<< "$1"
}

# Point the config of the backup to this device. Each base url keeps its host with
# the domain of this device instead of its tld, so b2b.store.nl becomes b2b.store.test.
# The link, static and media urls, such as a CDN, the cookie domain and the custom
# admin url are removed, and the search engine becomes the one of this device.
# Echoes 'STORE:<domain> <code>' for every store view, the default ones first.
# Magento has no command to delete config, and config:set checks the search engine,
# so this writes the core_config_data directly.
function mage_restore_local_config() {
  mage_php '
    [, $fallback, $domain, $prefix, $searchHost, $searchPort] = $argv;
    $resource = $objectManager->get(\Magento\Framework\App\ResourceConnection::class);
    $connection = $resource->getConnection();
    $table = $resource->getTableName("core_config_data");

    $local = function ($url) use ($domain) {
        $parts = parse_url((string) $url);
        if (empty($parts["host"])) {
            return null;
        }
        $labels = explode(".", $parts["host"]);
        if (count($labels) > 1) {
            array_pop($labels);
        }
        return "https://" . implode(".", $labels) . "." . $domain . "/" . ltrim($parts["path"] ?? "", "/");
    };

    $baseUrls = ["web/unsecure/base_url", "web/secure/base_url"];
    $urls = [];
    foreach ($connection->fetchAll($connection->select()->from($table)->where("path IN (?)", $baseUrls)) as $row) {
        $url = $local($row["value"]);
        if ($url === null) {
            $connection->delete($table, ["config_id = ?" => $row["config_id"]]);
            continue;
        }
        $connection->update($table, ["value" => $url], ["config_id = ?" => $row["config_id"]]);
        if ($row["path"] === "web/secure/base_url") {
            $urls[$row["scope"]][$row["scope_id"]] = $url;
        }
    }

    foreach ($baseUrls as $path) {
        $connection->insertOnDuplicate($table, ["scope" => "default", "scope_id" => 0, "path" => $path, "value" => $urls["default"][0] ?? $fallback], ["path"]);
    }
    $urls["default"][0] = $urls["default"][0] ?? $fallback;

    $others = [];
    foreach (["unsecure", "secure"] as $type) {
        foreach (["base_link_url", "base_static_url", "base_media_url"] as $key) {
            $others[] = "web/$type/$key";
        }
    }

    $connection->delete($table, ["path IN (?)" => $others]);
    $connection->delete($table, ["path = ?" => "web/cookie/cookie_domain"]);
    $connection->delete($table, ["path LIKE ?" => "admin/url/%"]);
    $connection->delete($table, ["path = ?" => "catalog/search/engine"]);
    $connection->delete($table, ["path LIKE ?" => "catalog/search/opensearch%"]);
    $connection->delete($table, ["path LIKE ?" => "catalog/search/elasticsearch%"]);

    $search = [
        "catalog/search/engine" => "opensearch",
        "catalog/search/opensearch_server_hostname" => $searchHost,
        "catalog/search/opensearch_server_port" => $searchPort,
        "catalog/search/opensearch_index_prefix" => $prefix,
        "catalog/search/opensearch_enable_auth" => "0",
        "catalog/search/opensearch_server_timeout" => "15",
    ];

    foreach ($search as $path => $value) {
        $connection->insert($table, ["scope" => "default", "scope_id" => 0, "path" => $path, "value" => $value]);
    }

    // A store view takes the url of its own scope, then of its website, then the default
    $stores = $connection->fetchAll(
        $connection->select()
            ->from(["s" => $resource->getTableName("store")], ["store_id", "code", "website_id"])
            ->join(["g" => $resource->getTableName("store_group")], "g.group_id = s.group_id", [])
            ->where("s.store_id > 0")
            ->order(new \Magento\Framework\DB\Sql\Expression("g.default_store_id = s.store_id DESC"))
            ->order("s.store_id")
    );

    foreach ($stores as $store) {
        $url = $urls["stores"][$store["store_id"]] ?? $urls["websites"][$store["website_id"]] ?? $urls["default"][0];
        echo "STORE:" . parse_url($url, PHP_URL_HOST) . " " . $store["code"] . PHP_EOL;
    }
  ' "$1" "$MAGE_DOMAIN" "$MAGE_DB_NAME" "$MAGE_SEARCH_HOST" "$MAGE_SEARCH_PORT"
}
