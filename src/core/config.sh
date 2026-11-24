# Defaults, any of these can be overridden in ~/.config/mage/config

MAGE_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/mage"
MAGE_CONFIG_FILE="${MAGE_CONFIG_DIR}/config"

MAGE_UPDATE_URL="https://raw.githubusercontent.com/GrimLink/mage/main/mage"
# The templates folder of this archive is synced to the config folder
MAGE_TEMPLATES_ARCHIVE="https://github.com/GrimLink/mage/tarball/main"

# The placeholders are replaced by your git user, see mage_system_user
MAGE_ADMIN_USER="acme"
MAGE_ADMIN_FIRSTNAME="acme"
MAGE_ADMIN_LASTNAME="admin"
MAGE_ADMIN_EMAIL="info@example.com"
MAGE_ADMIN_PASS="magento_123$"

# Take the defaults and confirm without asking, as -y does, such as for scripts and agents
MAGE_YES="${MAGE_YES:-0}"

# The edition 'mage create' defaults to: mage-os, mage-os-minimal, mage-os-mirror, community or enterprise
MAGE_EDITION="mage-os-mirror"

# The template 'mage create' applies: the name of a bundled template or a path to a json file.
# Empty picks one by edition: mage-os and mage-os-minimal for those, default for the others.
MAGE_CREATE_TEMPLATE=""

# Stores are served as https://<project>.<MAGE_DOMAIN>/
MAGE_DOMAIN="test"

# The mail catcher 'mage open mail' opens on your machine, Mailpit by default
MAGE_MAIL_URL="http://localhost:8025"

# An empty MAGE_DB_NAME uses the project folder name
MAGE_DB_HOST="localhost"
MAGE_DB_NAME=""
MAGE_DB_USER="root"
MAGE_DB_PASS="root"

MAGE_SEARCH_HOST="localhost"
MAGE_SEARCH_PORT="9200"
MAGE_REDIS_HOST="127.0.0.1"

# Deprecated, to be dropped: the packages are in the 'mage create' templates
MAGE_PACKAGES=()
MAGE_DEV_PACKAGES=()

# The modules mage setup disables, when the install has them.
# MageOS_PasskeyAuth depends on two factor auth, it is only for Mage-OS projects
# created before the mage-os template replaced it, and will be removed.
MAGE_DISABLE_MODULES=(
  MageOS_PasskeyAuth
  Magento_AdminAdobeImsTwoFactorAuth
  Magento_TwoFactorAuth
)

# The phpcs and phpcbf 'mage lint' runs, empty for the coding standard mage installs.
# Such as the phpcs-docker and phpcbf-docker of the Hyva coding standard, without php on your machine.
MAGE_LINT_PHPCS=""
MAGE_LINT_PHPCBF=""

# The npm scripts 'mage build' runs, and with --watch
MAGE_BUILD_SCRIPT="build"
MAGE_WATCH_SCRIPT="watch"

# Magento pins these, so they would always show as outdated
MAGE_OUTDATED_IGNORE=(
  symfony/finder
  symfony/process
)

# The handlers 'mage clean all' and 'mage purge' run, in order
MAGE_CLEAN_ALL="files redis varnish"

# Where 'mage backup' writes to, relative to the Magento root
MAGE_BACKUP_DIR="var/backups"
# The magerun2 table groups 'mage backup' leaves out of the dump, empty for none
MAGE_BACKUP_STRIP="@stripped"

# The Magento root on the server 'mage sync' pulls from, the one of Hypernode by default
MAGE_SYNC_PATH="/data/web/magento2"

# Each entry is 'path value', an entry without a value sets it empty
MAGE_STORE_CONFIG=(
  "currency/options/base EUR"
  "currency/options/default EUR"
  "currency/options/allow EUR,GBP"
  "general/country/default NL"
  "general/country/allow AT,BE,BG,HR,CY,CZ,DK,EE,FI,FR,DE,GR,HU,IE,IT,LV,LT,LU,MT,NL,PL,PT,RO,SK,SI,ES,SE,CH,NO,IS,LI,GB"
  "admin/usage/enabled 0"
  "admin/security/password_lifetime"
  "admin/security/password_is_forced 0"
  "catalog/seo/category_canonical_tag 1"
  "catalog/seo/product_canonical_tag 1"
  "siteation_debugbar/general/enabled 1"
)

# Like MAGE_STORE_CONFIG, but written to app/etc/env.php and locked in the admin.
# Mage-OS caps the session lifetime at 900 in the admin form, so a longer one must be locked
MAGE_ENV_CONFIG=(
  "admin/security/session_lifetime 86400"
)

# Defaults for the {{NAME}} placeholders in json files for 'mage add' go in the
# config as MAGE_VAR_<NAME>, such as MAGE_VAR_HYVA_PROJECT="my-project"

# The config runs as code, so like ssh with its config, refuse one that someone
# else could have changed: not owned by you, or writable by group or others
if [[ -f "$MAGE_CONFIG_FILE" ]]; then
  if [[ ! -O "$MAGE_CONFIG_FILE" ]] || [[ ! -O "$MAGE_CONFIG_DIR" ]] ||
    [[ -n "$(find "$MAGE_CONFIG_DIR" "$MAGE_CONFIG_FILE" -maxdepth 0 \( -perm -g=w -o -perm -o=w \) 2> /dev/null)" ]]; then
    mage_error "Not loading ${MAGE_CONFIG_FILE}, it is not owned by you or others can change it"
    mage_error "Fix it with: chmod 600 \"${MAGE_CONFIG_FILE}\" && chmod go-w \"${MAGE_CONFIG_DIR}\""
    exit 1
  fi

  # shellcheck source=/dev/null
  source "$MAGE_CONFIG_FILE"
fi

# Replace the placeholders of the admin user with your git user, the system user,
# for the commands that create one. A value set in the config is kept, and
# without a git user, such as on a CI runner, the placeholders stay.
function mage_system_user() {
  local name
  local email

  if [[ "$MAGE_ADMIN_FIRSTNAME" == "acme" ]] && name="$(git config --global --get user.name 2> /dev/null)"; then
    MAGE_ADMIN_FIRSTNAME="${name%% *}"
  fi

  if [[ "$MAGE_ADMIN_USER" == "acme" ]]; then
    MAGE_ADMIN_USER="$(echo "$MAGE_ADMIN_FIRSTNAME" | tr '[:upper:]' '[:lower:]')"
  fi

  if [[ "$MAGE_ADMIN_EMAIL" == "info@example.com" ]] && email="$(git config --global --get user.email 2> /dev/null)"; then
    MAGE_ADMIN_EMAIL="$email"
  fi
}

# Add a setting to the config file, quoted so the file stays valid bash
function mage_config_save() {
  mkdir -p "$MAGE_CONFIG_DIR"

  if [[ ! -f "$MAGE_CONFIG_FILE" ]]; then
    touch "$MAGE_CONFIG_FILE"
    chmod 600 "$MAGE_CONFIG_FILE"
  fi

  printf '%s=%q\n' "$1" "$2" >> "$MAGE_CONFIG_FILE"
  mage_notice "Saved ${1} in ${MAGE_CONFIG_FILE}"
}
