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

# The edition 'mage create' defaults to: mage-os, community or enterprise
MAGE_EDITION="mage-os"

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

MAGE_PACKAGES=(
  cweagans/composer-patches
  yireo/magento2-theme-commands
  swissup/module-ignition
  community-engineering/language-nl_nl
)

MAGE_DEV_PACKAGES=(
  avstudnitz/scopehint2
  spatie/ray
  siteation/magento2-debugbar
)

# The modules mage setup disables, when the install has them: two factor auth,
# and the bfcache of Mage-OS, which conflicts with the BFCache patches and Hyva
MAGE_DISABLE_MODULES=(
  Magento_AdminAdobeImsTwoFactorAuth
  Magento_TwoFactorAuth
  MageOS_ThemeOptimization
)

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
  "admin/security/session_lifetime 86400"
  "admin/security/password_lifetime"
  "admin/security/password_is_forced 0"
  "catalog/seo/category_canonical_tag 1"
  "catalog/seo/product_canonical_tag 1"
  "siteation_debugbar/general/enabled 1"
)

# Defaults for the {{NAME}} placeholders in json files for 'mage add' go in the
# config as MAGE_VAR_<NAME>, such as MAGE_VAR_HYVA_PROJECT="my-project"

if [[ -f "$MAGE_CONFIG_FILE" ]]; then
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
