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

source "${MAGE_SRC}/env/local.sh"
source "${MAGE_SRC}/env/valet.sh"
source "${MAGE_SRC}/env/warden.sh"

source "${MAGE_SRC}/commands/meta.sh"
source "${MAGE_SRC}/commands/create.sh"
source "${MAGE_SRC}/commands/setup.sh"
source "${MAGE_SRC}/commands/nuke.sh"
source "${MAGE_SRC}/commands/add.sh"

# Run the given command, where anything unknown goes to bin/magento
function mage_main() {
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
    *)
      mage_root_enter || exit 1
      mage_env_init

      case "$1" in
        "nuke" | "destroy")
          mage_cmd_nuke "${@:2}"
          ;;
        "add")
          mage_cmd_add "${@:2}"
          ;;
        *)
          mage_passthrough "$@"
          ;;
      esac
      ;;
  esac
}

# Only run when executed, so the tests can source this file
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  mage_main "$@"
fi
