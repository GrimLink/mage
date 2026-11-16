# MageBox, PHP and Nginx run on the host, the services in shared containers,
# see https://magebox.dev/. mage create does not support it, 'magebox new' or
# 'magebox init' sets up the project, after which mage takes over.

MAGEBOX_BIN="${HOME}/.magebox/bin"

function env_magebox_available() {
  command -v magebox &> /dev/null
}

function env_magebox_detect() {
  env_magebox_available && mage_magebox_config > /dev/null
}

# The wrappers in ~/.magebox/bin pick the PHP version of the project,
# also when they are not in the PATH
function env_magebox_apply() {
  MAGENTO_CLI="${MAGEBOX_BIN}/php bin/magento"
  MAGERUN_CLI="${MAGEBOX_BIN}/magerun2"
  PHP_CLI="${MAGEBOX_BIN}/php"
  COMPOSER_CLI="${MAGEBOX_BIN}/composer"

  local name
  local version
  { read -r name; read -r version; } < <(mage_magebox_values)

  MAGE_DOMAIN="test"
  MAGE_DB_HOST="127.0.0.1:$(mage_magebox_db_port "$version")"
  MAGE_DB_NAME="${name:-$MAGE_DB_NAME}"
  # The database name of MageBox, which replaces the hyphens of the project name
  MAGE_DB_NAME="${MAGE_DB_NAME//-/_}"
  MAGE_DB_USER="root"
  MAGE_DB_PASS="magebox"
  MAGE_SEARCH_HOST="127.0.0.1"
  MAGE_SEARCH_PORT="9200"
  MAGE_REDIS_HOST="127.0.0.1"
}

# Echo the project config, .magebox.yaml or the legacy .magebox
function mage_magebox_config() {
  local file

  for file in .magebox.yaml .magebox; do
    if [[ -f "$file" ]]; then
      echo "$file"
      return 0
    fi
  done

  return 1
}

# Echo the name and the database version of the project, a line each, read in one
# pass with the local override first. A line match, not a YAML parser, enough for
# the top level name and the mysql or mariadb under services.
function mage_magebox_values() {
  local files=()
  local file

  for file in .magebox.local.yaml "$(mage_magebox_config)"; do
    if [[ -f "$file" ]]; then
      files+=("$file")
    fi
  done

  if [[ ${#files[@]} -eq 0 ]]; then
    printf '\n\n'
    return
  fi

  awk '
    function value(line) {
      sub(/^[^:]*:[ \t]*/, "", line)
      sub(/[ \t]+#.*$/, "", line)
      gsub(/["\047 \t]/, "", line)
      return line
    }
    /^name:/ && name == "" { name = value($0) }
    /^[ \t]+(mysql|mariadb):/ && db == "" { db = value($0) }
    END { print name; print db }
  ' "${files[@]}"
}

# Echo the port of the database container, MageBox runs one per version on
# 33000 plus the version without its dot, such as 33080 for MySQL 8.0
function mage_magebox_db_port() {
  local version="$1"

  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+$ ]]; then
    version="8.0"
  fi

  echo $((33000 + 10#${version//./}))
}

function env_magebox_nuke() {
  env_local_nuke "$@"

  magebox stop
  mage_check $? "MageBox project stopped"
}

function env_magebox_add_store() {
  magebox domain add "$1" --store-code="$2"
}

function env_magebox_open_mail() {
  magebox mailpit open
}
