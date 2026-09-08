# Per project isolation of Redis and OpenSearch.
#
# Without this every project on one machine shares Redis db 0, 1 and 2, and
# after a database import often the same OpenSearch index prefix as well.
# A 'cache:flush' then clears the cache of every project at once, and a
# reindex overwrites the indices of another project.
#
# Warden already gives each project its own containers, so isolation is
# skipped there.

# Echo the folder holding the Redis pid and log files, and create it when missing
function mage_redis_dir() {
  local redis_dir="$(mage_config_dir)/redis"
  mkdir -p "$redis_dir"
  echo "$redis_dir"
}

# Echo the registry file, and create it with a header when missing
function mage_redis_registry() {
  local registry="$(mage_config_dir)/redis-ports.tsv"

  if [[ ! -f "$registry" ]]; then
    printf '# Redis port per project, managed by mage isolate\n# slug\tport\n' > "$registry"
  fi

  echo "$registry"
}

# Echo the port registered for a slug, or nothing when it is not registered
function mage_redis_lookup_port() {
  awk -v slug="$1" '$1 == slug { print $2; exit }' "$(mage_redis_registry)"
}

# Return 0 when something already listens on a port
function mage_port_in_use() {
  if command -v nc &> /dev/null; then
    nc -z 127.0.0.1 "$1" &> /dev/null
  else
    $REDIS_CLI -p "$1" ping &> /dev/null
  fi
}

# Echo the port for a slug, registering the next free one when it is new.
# A registry instead of a hash of the path, since a hash can collide and this
# cannot, and it stays readable when you need to know what runs where.
function mage_redis_port() {
  local slug="$1"
  local registry="$(mage_redis_registry)"
  local port="$(mage_redis_lookup_port "$slug")"

  if [[ -n "$port" ]]; then
    echo "$port"
    return
  fi

  local highest="$(awk '$2 ~ /^[0-9]+$/ && $2 > max { max = $2 } END { print max + 0 }' "$registry")"

  if [[ $highest -ge $MAGE_REDIS_PORT_BASE ]]; then
    port=$(( highest + 1 ))
  else
    port=$MAGE_REDIS_PORT_BASE
  fi

  # Skip ports taken by something that is not in the registry
  while mage_port_in_use "$port"; do
    port=$(( port + 1 ))
  done

  printf '%s\t%s\n' "$slug" "$port" >> "$registry"
  echo "$port"
}

# Start the Redis instance for a slug, does nothing when it already runs
function mage_redis_start() {
  local slug="$1"
  local port="${2:-$(mage_redis_port "$slug")}"
  local redis_dir="$(mage_redis_dir)"

  if $REDIS_CLI -p "$port" ping &> /dev/null; then
    return 0
  fi

  if ! command -v redis-server &> /dev/null; then
    echo -e " [${RED}✗${RESET}] redis-server not found, install it with 'brew install redis'"
    return 1
  fi

  # No persistence, since the cache of a dev project is disposable.
  # allkeys-lru evicts under pressure, where the default noeviction
  # starts refusing writes, which Magento surfaces as a 500.
  redis-server \
    --port "$port" \
    --bind 127.0.0.1 \
    --daemonize yes \
    --save '' \
    --appendonly no \
    --maxmemory "$MAGE_REDIS_MAXMEMORY" \
    --maxmemory-policy allkeys-lru \
    --pidfile "${redis_dir}/${slug}.pid" \
    --logfile "${redis_dir}/${slug}.log"
}

# Stop the Redis instance for a slug
function mage_redis_stop() {
  local slug="$1"
  local port="$(mage_redis_lookup_port "$slug")"

  if [[ -z "$port" ]]; then
    echo "No Redis port registered for '${slug}'"
    return 1
  fi

  $REDIS_CLI -p "$port" shutdown nosave &> /dev/null
  echo -e " [${GREEN}✓${RESET}] ${slug} on port ${port} stopped"
}

# Run a command for every line in the registry
function mage_redis_each() {
  local action="$1"
  local slug
  local port

  while read -r slug port; do
    [[ -z "$slug" || "$slug" == \#* ]] && continue
    $action "$slug" "$port"
  done < "$(mage_redis_registry)"
}

function mage_redis_start_all() {
  mage_redis_each mage_redis_start_reported
}

function mage_redis_start_reported() {
  if mage_redis_start "$1" "$2"; then
    echo -e " [${GREEN}✓${RESET}] ${1} on port ${2}"
  fi
}

function mage_redis_stop_all() {
  mage_redis_each mage_redis_stop
}

# Echo 'host port cache_db page_db session_db' based on app/etc/env.php
function get_mage_redis_config() {
  $PHP_CLI -r '
    $env = @include "app/etc/env.php";
    if (!is_array($env)) { exit(1); }

    $cache = $env["cache"]["frontend"]["default"]["backend_options"] ?? [];
    $page = $env["cache"]["frontend"]["page_cache"]["backend_options"] ?? [];
    $session = ($env["session"]["save"] ?? "") === "redis" ? ($env["session"]["redis"] ?? []) : [];

    if (!$cache && !$page && !$session) { exit(1); }

    echo implode(" ", [
      $cache["server"] ?? $page["server"] ?? $session["host"] ?? "127.0.0.1",
      $cache["port"] ?? $page["port"] ?? $session["port"] ?? "6379",
      $cache["database"] ?? "-",
      $page["database"] ?? "-",
      $session["database"] ?? "-",
    ]);
  ' 2>/dev/null
}

# Echo the OpenSearch index prefix of this project.
#
# app/etc/env.php is read first, since a value under 'system' wins at runtime,
# with core_config_data as the fallback. Both are read directly instead of
# through 'config:show', so a scan over many projects stays quick and still
# reports a project that no longer boots.
function get_mage_search_prefix() {
  local prefix="$($PHP_CLI -r '
    $env = @include "app/etc/env.php";
    if (!is_array($env)) { exit; }

    $path = "catalog/search/opensearch_index_prefix";
    $locked = $env["system"]["default"]["catalog"]["search"]["opensearch_index_prefix"] ?? null;

    if ($locked !== null) {
      echo $locked;
      exit;
    }

    $db = $env["db"]["connection"]["default"] ?? [];
    if (!$db) { exit; }

    try {
      $pdo = new PDO(
        sprintf("mysql:host=%s;dbname=%s", $db["host"] ?? "localhost", $db["dbname"] ?? ""),
        $db["username"] ?? "",
        $db["password"] ?? "",
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_TIMEOUT => 2]
      );
      $table = ($env["db"]["table_prefix"] ?? "") . "core_config_data";
      $stmt = $pdo->prepare("SELECT value FROM `" . $table . "` WHERE path = ? LIMIT 1");
      $stmt->execute([$path]);
      echo (string) $stmt->fetchColumn();
    } catch (Throwable $e) {
      // An unreachable database falls through to the default below
    }
  ' 2>/dev/null)"

  echo "${prefix:-magento2}"
}

# Pin the search config in app/etc/env.php.
# A value under 'system' takes precedence over core_config_data and shows as
# read only in the admin, so importing a database can no longer drag another
# project its index prefix along.
function mage_lock_search_config() {
  local prefix="$1"
  local host="${2:-localhost}"
  local port="${3:-9200}"

  $MAGENTO_CLI config:set --lock-env catalog/search/engine opensearch &> /dev/null
  $MAGENTO_CLI config:set --lock-env catalog/search/opensearch_server_hostname "$host" &> /dev/null
  $MAGENTO_CLI config:set --lock-env catalog/search/opensearch_server_port "$port" &> /dev/null
  $MAGENTO_CLI config:set --lock-env catalog/search/opensearch_index_prefix "$prefix" &> /dev/null
  $MAGENTO_CLI config:set --lock-env catalog/search/opensearch_enable_auth 0 &> /dev/null
  $MAGENTO_CLI config:set --lock-env catalog/search/opensearch_server_timeout 15 &> /dev/null

  echo -e " [${GREEN}✓${RESET}] Search prefix '${prefix}' pinned in app/etc/env.php"
}

# Point this project at its own Redis instance and pin its search prefix
function mage_isolate() {
  local name="$(basename "$(pwd)")"

  if [[ $WARDEN == 1 ]]; then
    echo "Warden runs Redis and OpenSearch per project already, nothing to isolate"
    return 0
  fi

  if [[ ! -f app/etc/env.php ]]; then
    echo "No app/etc/env.php found, run 'mage setup' first"
    return 1
  fi

  local port="$(mage_redis_port "$name")"

  if ! mage_redis_start "$name" "$port"; then
    return 1
  fi
  echo -e " [${GREEN}✓${RESET}] Redis for '${name}' on port ${port}"

  # The db numbers stay 0, 1 and 2 in every project, the port is what
  # separates them, so there is nothing to allocate and nothing to look up.
  $MAGENTO_CLI setup:config:set -n \
    --cache-backend=redis \
    --cache-backend-redis-server=127.0.0.1 \
    --cache-backend-redis-port="$port" \
    --cache-backend-redis-db=0 \
    --cache-id-prefix="${name}_" \
    --page-cache=redis \
    --page-cache-redis-server=127.0.0.1 \
    --page-cache-redis-port="$port" \
    --page-cache-redis-db=1 \
    --page-cache-id-prefix="${name}_" \
    --session-save=redis \
    --session-save-redis-host=127.0.0.1 \
    --session-save-redis-port="$port" \
    --session-save-redis-db=2 \
    --session-save-redis-max-concurrency=20 &> /dev/null

  echo -e " [${GREEN}✓${RESET}] Cache, page cache and sessions moved to port ${port}"

  mage_lock_search_config "$(get_mage_search_prefix)"

  echo -e "\n${YELLOW}Note: run 'mage reindex' to rebuild the indices under the pinned prefix${RESET}"
}

# Echo the root of every Magento project below a path
function mage_find_projects() {
  find "${1:-$(pwd)}" -maxdepth "$MAGE_SCAN_DEPTH" -type f -path '*/app/etc/env.php' \
    -not -path '*/vendor/*' 2> /dev/null |
    sed 's|/app/etc/env.php$||' |
    sort
}

# Isolate every Magento project below a path
function mage_isolate_all() {
  local start_dir="$(pwd)"
  local project

  while IFS= read -r project; do
    echo -e "\n${BOLD}$(basename "$project")${RESET}"
    cd "$project" && mage_isolate
    cd "$start_dir"
  done < <(mage_find_projects "$1")
}

# Report the Redis instance and search prefix of every project below a path,
# and flag the ones that share either of them
function mage_isolate_status() {
  local start_dir="$(pwd)"
  local report="$(mktemp)"
  local project
  local redis_config
  local redis
  local prefix

  printf "%-34s %-18s %s\n" "PROJECT" "REDIS" "SEARCH PREFIX"

  while IFS= read -r project; do
    cd "$project"

    redis_config="$(get_mage_redis_config)"
    redis="files"
    if [[ -n "$redis_config" ]]; then
      redis="$(echo "$redis_config" | awk '{ print $1 ":" $2 }')"
    fi
    prefix="$(get_mage_search_prefix)"

    printf "%-34s %-18s %s\n" "$(basename "$project")" "$redis" "$prefix"
    printf '%s\t%s\n' "$redis" "$prefix" >> "$report"

    cd "$start_dir"
  done < <(mage_find_projects "$1")

  local shared_redis="$(awk -F'\t' '$1 != "files" { print $1 }' "$report" | sort | uniq -d)"
  local shared_prefix="$(awk -F'\t' '{ print $2 }' "$report" | sort | uniq -d)"

  rm -f "$report"

  if [[ -n "$shared_redis" ]]; then
    echo -e "\n${RED}Shared Redis instances:${RESET}"
    echo "$shared_redis" | sed 's/^/  /'
  fi

  if [[ -n "$shared_prefix" ]]; then
    echo -e "\n${RED}Shared search prefixes:${RESET}"
    echo "$shared_prefix" | sed 's/^/  /'
  fi

  if [[ -z "$shared_redis" && -z "$shared_prefix" ]]; then
    echo -e "\n [${GREEN}✓${RESET}] Every project has its own Redis instance and search prefix"
  fi
}

# Install a login agent that starts the Redis instance of every project
function mage_isolate_agent() {
  local script="$(mage_redis_dir)/start-all.sh"
  local mage_bin="$(command -v mage || echo mage)"

  {
    echo "#!/bin/bash"
    echo "# Generated by 'mage isolate agent'"
    echo "exec \"${mage_bin}\" isolate start"
  } > "$script"
  chmod +x "$script"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    local plist="$HOME/Library/LaunchAgents/dev.mage.redis.plist"
    mkdir -p "$(dirname "$plist")"

    cat > "$plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>dev.mage.redis</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${script}</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$(mage_redis_dir)/agent.log</string>
  <key>StandardErrorPath</key>
  <string>$(mage_redis_dir)/agent.log</string>
</dict>
</plist>
PLIST

    launchctl unload "$plist" &> /dev/null
    launchctl load "$plist" &> /dev/null
    echo -e " [${GREEN}✓${RESET}] Installed ${plist}"
    return
  fi

  if ! command -v systemctl &> /dev/null; then
    echo "No launchd or systemd found, run 'mage isolate start' yourself after a reboot"
    return 1
  fi

  local unit="$HOME/.config/systemd/user/mage-redis.service"
  mkdir -p "$(dirname "$unit")"

  cat > "$unit" << UNIT
[Unit]
Description=Redis instances for the Magento projects managed by mage

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash ${script}

[Install]
WantedBy=default.target
UNIT

  systemctl --user daemon-reload &> /dev/null
  systemctl --user enable --now mage-redis.service &> /dev/null
  echo -e " [${GREEN}✓${RESET}] Installed ${unit}"
}

# Delete the OpenSearch indices that no project below a path claims.
# This is what clears out the indices left behind by a shared prefix.
function mage_isolate_prune() {
  local start_dir="$(pwd)"
  local host="localhost"
  local port="9200"
  local prefixes="$(mktemp)"
  local project

  while IFS= read -r project; do
    cd "$project"
    get_mage_search_prefix >> "$prefixes"
    cd "$start_dir"
  done < <(mage_find_projects "$1")

  local indices="$(curl -s "${host}:${port}/_cat/indices?h=index" | tr -d ' ' | sed '/^$/d' | sort)"

  if [[ -z "$indices" ]]; then
    echo "Could not reach OpenSearch on ${host}:${port}"
    rm -f "$prefixes"
    return 1
  fi

  local owned="$(sort -u "$prefixes")"
  local orphans=""
  local index
  local prefix
  local claimed

  while IFS= read -r index; do
    claimed=0

    while IFS= read -r prefix; do
      [[ -z "$prefix" ]] && continue
      if [[ "$index" == "${prefix}_"* ]]; then
        claimed=1
        break
      fi
    done <<< "$owned"

    if [[ $claimed == 0 ]]; then
      orphans+="${index}"$'\n'
    fi
  done <<< "$indices"

  rm -f "$prefixes"

  if [[ -z "${orphans//[[:space:]]/}" ]]; then
    echo -e " [${GREEN}✓${RESET}] Every index belongs to a known project"
    return
  fi

  echo -e "${BOLD}Indices that no project claims:${RESET}"
  echo "$orphans" | sed '/^$/d' | sed 's/^/  /'

  if mage_confirm "Delete these indices?"; then
    while IFS= read -r index; do
      [[ -z "$index" ]] && continue
      curl -s -X DELETE "${host}:${port}/${index}" > /dev/null
    done <<< "$orphans"
    echo -e " [${GREEN}✓${RESET}] Deleted"
  fi
}
