# Global variables
RESET='\033[0m'
BOLD='\033[1m'
ITALIC='\033[3m'
RED='\033[0;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'

GITNAME="$(git config --global --get user.name | head -n1 | cut -d " " -f1)"
GITEMAIL="$(git config --global --get user.email)"
ADMINNAME="$(echo "$GITNAME" | tr '[:upper:]' '[:lower:]')"
ADMINEMAIL="${GITEMAIL}"
ADMINPASS="m2_admin123$"

WARDEN=0
MAGENTO_CLI="bin/magento"
MAGERUN_CLI=""
REDIS_CLI="redis-cli"
VARNISH_CLI="varnishadm" # We never use varnish on a local machine, and prefer to never use it
PHP_CLI="php"
COMPOSER_CLI="composer"
NODE_CLI="node"
NPM_CLI="npm"
PURGE_CLI="rm -rf"
OPEN_CLI="xdg-open" # Linux
GET_CLI="wget" # Linux

# OSX
if [[ "$OSTYPE" == "darwin"* ]]; then
  OPEN_CLI="open"
  GET_CLI="curl -O"
fi

# Check if this is the Magento 2 root
if [[ ! -d app/etc ]]; then
  # Allow the following commands to run, even if the folder is not root Magento,
  # if else exit mage
  if [[ $1 != "help" ]] && [[ $1 != "self-update" ]] && [[ $1 != "install" ]] && [[ $1 != "create" ]]; then
    echo "This does not look like the Magento 2 root folder, aborting.." && exit 1
  fi
fi

# Magerun
NO_MAGERUN_MSG="Magerun2 is not installed"
if command -v magerun2 &>/dev/null; then
  MAGERUN_CLI="magerun2"
elif command -v n98-magerun2 &>/dev/null; then
  MAGERUN_CLI="n98-magerun2"
fi

# Warden Support
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
  # Run removal within environment, so that changes are in effect immediately.
  # Changes will get synced back to the host
  PURGE_CLI="warden env exec -T php-fpm rm -rf"
fi
