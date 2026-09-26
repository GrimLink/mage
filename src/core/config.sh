# Defaults, any of these can be overridden in ~/.config/mage/config

MAGE_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/mage"
MAGE_CONFIG_FILE="${MAGE_CONFIG_DIR}/config"

MAGE_UPDATE_URL="https://raw.githubusercontent.com/GrimLink/mage/main/mage"
# The templates folder of this archive is synced to the config folder
MAGE_TEMPLATES_ARCHIVE="https://github.com/GrimLink/mage/tarball/main"

GIT_NAME="$(git config --global --get user.name 2> /dev/null | head -n1 | cut -d " " -f1)"
GIT_EMAIL="$(git config --global --get user.email 2> /dev/null)"

MAGE_ADMIN_USER="$(echo "$GIT_NAME" | tr '[:upper:]' '[:lower:]')"
MAGE_ADMIN_FIRSTNAME="${GIT_NAME}"
MAGE_ADMIN_LASTNAME="admin"
MAGE_ADMIN_EMAIL="${GIT_EMAIL}"
MAGE_ADMIN_PASS="magento_123$"

# The edition 'mage create' defaults to: mage-os, community or enterprise
MAGE_EDITION="mage-os"

# Stores are served as https://<project>.<MAGE_DOMAIN>/
MAGE_DOMAIN="test"

# An empty MAGE_DB_NAME uses the project folder name
MAGE_DB_HOST="localhost"
MAGE_DB_NAME=""
MAGE_DB_USER="root"
MAGE_DB_PASS="root"

MAGE_SEARCH_HOST="localhost"
MAGE_SEARCH_PORT="9200"
MAGE_REDIS_HOST="127.0.0.1"

MAGE_PACKAGES=(
  cweagans/composer-patches
  yireo/magento2-theme-commands
  swissup/module-ignition
  community-engineering/language-nl_nl
)

MAGE_DEV_PACKAGES=(
  avstudnitz/scopehint2
  spatie/ray
)

# Magento pins these, so they would always show as outdated
MAGE_OUTDATED_IGNORE=(
  symfony/finder
  symfony/process
)

# The handlers 'mage clean all' and 'mage purge' run, in order
MAGE_CLEAN_ALL="files redis varnish"

# Each entry is 'path value', an entry without a value sets it empty
MAGE_STORE_CONFIG=(
  "currency/options/base EUR"
  "currency/options/default EUR"
  "currency/options/allow EUR,GBP"
  "general/country/default NL"
  "general/country/allow AT,BE,BG,HR,CY,CZ,DK,EE,FI,FR,DE,GR,HU,IE,IT,LV,LT,LU,MT,NL,PL,PT,RO,SK,SI,ES,SE,CH,NO,IS,LI,GB"
  "admin/usage/enabled 0"
  "admin/security/session_lifetime 86400"
  "admin/security/password_lifetime"
  "admin/security/password_is_forced 0"
  "catalog/seo/category_canonical_tag 1"
  "catalog/seo/product_canonical_tag 1"
)

# Defaults for the {{NAME}} placeholders in json files for 'mage add' go in the
# config as MAGE_VAR_<NAME>, such as MAGE_VAR_HYVA_PROJECT="my-project"

if [[ -f "$MAGE_CONFIG_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$MAGE_CONFIG_FILE"
fi
