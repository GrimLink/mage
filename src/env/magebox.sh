# MageBox, PHP and Nginx run on the host, the services in shared containers,
# see https://magebox.dev/. Mage creates and installs the project itself,
# MageBox only adds its config, vhost, certificate and database.

MAGEBOX_BIN="${HOME}/.magebox/bin"
MAGEBOX_GLOBAL_CONFIG="${HOME}/.magebox/config.yaml"

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
  local tld
  { read -r name; read -r version; read -r tld; } < <(mage_magebox_values)

  MAGE_DOMAIN="${tld:-test}"
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

# Echo the name and the database version of the project, and the tld of the global
# config, a line each. Read in one pass, with the local override of the project first.
# A line match, not a YAML parser, enough for these top level keys and the mysql
# or mariadb under services.
function mage_magebox_values() {
  local files=()
  local file

  for file in .magebox.local.yaml "$(mage_magebox_config)" "$MAGEBOX_GLOBAL_CONFIG"; do
    if [[ -f "$file" ]]; then
      files+=("$file")
    fi
  done

  if [[ ${#files[@]} -eq 0 ]]; then
    printf '\n\n\n'
    return
  fi

  awk -v global="$MAGEBOX_GLOBAL_CONFIG" '
    function value(line) {
      sub(/^[^:]*:[ \t]*/, "", line)
      sub(/[ \t]+#.*$/, "", line)
      gsub(/["\047 \t]/, "", line)
      return line
    }
    FILENAME == global { if (/^tld:/ && tld == "") tld = value($0); next }
    /^name:/ && name == "" { name = value($0) }
    /^[ \t]+(mysql|mariadb):/ && db == "" { db = value($0) }
    END { print name; print db; print tld }
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

# Create the composer project, then its MageBox config, vhost, certificate and database.
# Without --install composer only needs a PHP that runs it, the project PHP comes
# from 'magebox init', which reads it from composer.json or takes the MageBox default.
function env_magebox_create_project() {
  local name="$1"

  env_local_create_project "$@" || return 1

  magebox init "$name" < /dev/null || return 1
  magebox start || return 1

  env_magebox_apply
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
