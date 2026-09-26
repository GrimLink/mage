#!/usr/bin/env bash

# Mage is a collection of easy commands and aliases for bin/magento
# For those who hate typing long shell commands

set -o pipefail

MAGE_VERSION="dev"
MAGE_SELF="${BASH_SOURCE[0]}"
MAGE_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

source "${MAGE_SRC}/core/output.sh"
source "${MAGE_SRC}/core/config.sh"
source "${MAGE_SRC}/core/tools.sh"
source "${MAGE_SRC}/core/env.sh"
source "${MAGE_SRC}/core/root.sh"
source "${MAGE_SRC}/core/helpers.sh"
source "${MAGE_SRC}/core/handlers.sh"
source "${MAGE_SRC}/core/templates.sh"

source "${MAGE_SRC}/env/local.sh"
source "${MAGE_SRC}/env/valet.sh"
source "${MAGE_SRC}/env/warden.sh"
source "${MAGE_SRC}/env/ddev.sh"

source "${MAGE_SRC}/commands/meta.sh"
source "${MAGE_SRC}/commands/create.sh"
source "${MAGE_SRC}/commands/setup.sh"
source "${MAGE_SRC}/commands/nuke.sh"
source "${MAGE_SRC}/commands/run.sh"
source "${MAGE_SRC}/commands/add.sh"
source "${MAGE_SRC}/commands/add-json.sh"
source "${MAGE_SRC}/commands/remove.sh"
source "${MAGE_SRC}/commands/update.sh"
source "${MAGE_SRC}/commands/outdated.sh"
source "${MAGE_SRC}/commands/add/theme.sh"
source "${MAGE_SRC}/commands/add/module.sh"
source "${MAGE_SRC}/commands/add/hyva.sh"
source "${MAGE_SRC}/commands/add/storeinfo.sh"
source "${MAGE_SRC}/commands/add/patch.sh"
source "${MAGE_SRC}/commands/add/bfcache.sh"
source "${MAGE_SRC}/commands/add/admin.sh"
source "${MAGE_SRC}/commands/add/customer.sh"
source "${MAGE_SRC}/commands/clean.sh"
source "${MAGE_SRC}/commands/clean/files.sh"
source "${MAGE_SRC}/commands/clean/redis.sh"
source "${MAGE_SRC}/commands/clean/varnish.sh"
source "${MAGE_SRC}/commands/clean/opensearch.sh"
source "${MAGE_SRC}/commands/clean/sample-files.sh"
source "${MAGE_SRC}/commands/show.sh"
source "${MAGE_SRC}/commands/show/stores.sh"
source "${MAGE_SRC}/commands/show/modules.sh"
source "${MAGE_SRC}/commands/show/themes.sh"

# Commands that run outside a Magento project, setup finds the root itself
MAGE_ROOTLESS_COMMANDS="help version self-update create setup"

# Run the given command, where anything unknown goes to bin/magento
function mage_main() {
  if [[ " $MAGE_ROOTLESS_COMMANDS " != *" $1 "* ]]; then
    mage_root_enter || exit 1
    mage_env_init
  fi

  case "$1" in
    "help")
      mage_cmd_version
      mage_cmd_help
      ;;
    "version")
      mage_cmd_version
      ;;
    "self-update")
      mage_cmd_self_update
      ;;
    "create")
      mage_cmd_create "${@:2}"
      ;;
    "setup")
      mage_cmd_setup "${@:2}"
      ;;
    "nuke" | "destroy")
      mage_cmd_nuke "${@:2}"
      ;;
    "add")
      mage_cmd_add "${@:2}"
      ;;
    "del" | "remove")
      mage_cmd_remove "${@:2}"
      ;;
    "upd" | "update")
      mage_cmd_update "${@:2}"
      ;;
    "outdated")
      mage_cmd_outdated "${@:2}"
      ;;
    "show")
      mage_cmd_show "${@:2}"
      ;;
    "run")
      mage_cmd_run "${@:2}"
      ;;
    "clean" | "purge")
      mage_cmd_clean "${@:2}"
      ;;
    *)
      $MAGENTO_CLI "$@"
      ;;
  esac
}

# Only run when executed, so the tests can source this file
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  mage_main "$@"
fi
