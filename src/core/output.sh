RESET=""
BOLD=""
ITALIC=""
RED=""
GREEN=""
YELLOW=""
BLUE=""

if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
  RESET=$'\033[0m'
  BOLD=$'\033[1m'
  ITALIC=$'\033[3m'
  RED=$'\033[31m'
  GREEN=$'\033[32m'
  YELLOW=$'\033[33m'
  BLUE=$'\033[34m'
fi

function mage_info() {
  printf '%s\n' "$*"
}

# Notices go to stderr, so they never end up in piped command output
function mage_notice() {
  printf '%s\n' "${BLUE}$*${RESET}" >&2
}

function mage_warn() {
  printf '%s\n' "${YELLOW}$*${RESET}" >&2
}

function mage_error() {
  printf '%s\n' "${RED}$*${RESET}" >&2
}

# Print a checklist line, marked as done or failed by the first argument
function mage_check() {
  if [[ "$1" == 0 ]]; then
    printf ' [%s] %s\n' "${GREEN}✓${RESET}" "$2"
  else
    printf ' [%s] %s\n' "${RED}✗${RESET}" "$2"
  fi
}
