MAGE_VERSION="2.4.0"

# Check if this is the Magento 2 root
if [[ ! -d app/etc ]]; then
  case "$1" in
    version|help|self-update|install|setup|create)
      # Allow these commands to run even if not in Magento root
      ;;
    *)
      echo "This does not look like the Magento 2 root folder, aborting.." && exit 1
      ;;
  esac
fi

# Global variables
RESET='\033[0m'
BOLD='\033[1m'
ITALIC='\033[3m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'

GITNAME="$(git config --global --get user.name | head -n1 | cut -d " " -f1)"
GITEMAIL="$(git config --global --get user.email)"
ADMINNAME="$(echo "$GITNAME" | tr '[:upper:]' '[:lower:]')"
ADMINEMAIL="${GITEMAIL}"
ADMINPASS="magento_123$"

# Load NVM if available, so the node version is the one used by the system
[ -s "$HOME/.nvm/nvm.sh" ] && \. "$HOME/.nvm/nvm.sh"

# Env Variables
VALET=0
WARDEN=0

MAGENTO_CLI="bin/magento"
MAGERUN_CLI=""
REDIS_CLI="redis-cli"
VARNISH_CLI="varnishadm"
PHP_CLI="php"
COMPOSER_CLI="composer"
NODE_CLI="node"
NPM_CLI="npm"
RSYNC_CLI="rsync"
PURGE_CLI="rm -rf"
OPEN_CLI="xdg-open" # Linux
GET_CLI="wget" # Linux

# OSX Env
if [[ "$OSTYPE" == "darwin"* ]]; then
  OPEN_CLI="open"
  GET_CLI="curl -O"
fi

# Magerun
if command -v magerun2 &>/dev/null && magerun2 --version &>/dev/null; then
  MAGERUN_CLI="magerun2"
elif command -v n98-magerun2 &>/dev/null && n98-magerun2 --version &>/dev/null; then
  MAGERUN_CLI="n98-magerun2"
fi

# Valet Env
if [[ $(valet -V | cut -f1,2 -d ' ') == "Laravel Valet" ]]; then
  VALET=1
fi

# Warden Env
if [ -f .env ] && grep -q "WARDEN_ENV_NAME" .env && [[ ! "$PATH" == /var/www/html* ]]; then
  WARDEN=1
  MAGENTO_CLI="warden env exec php-fpm bin/magento"
  MAGERUN_CLI="warden env exec php-fpm n98-magerun"
  REDIS_CLI="warden env exec redis redis-cli"
  VARNISH_CLI="warden env exec -T varnish varnishadm"
  PHP_CLI="warden env exec php-fpm php"
  COMPOSER_CLI="warden env exec php-fpm composer"
  NODE_CLI="warden env exec php-fpm node"
  NPM_CLI="warden env exec php-fpm npm"
  RSYNC_CLI="warden env exec -T php-fpm rsync"
  # Run removal within environment, so that changes are in effect immediately.
  # Changes will get synced back to the host
  PURGE_CLI="warden env exec -T php-fpm rm -rf"
fi
