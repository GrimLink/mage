# Echo the mage config folder, and create it when missing
function mage_config_dir() {
  mkdir -p "$MAGE_CONFIG_DIR"
  echo "$MAGE_CONFIG_DIR"
}

# Ask a question, where an empty answer takes the default.
# The prompt goes to stderr, so this stays usable inside a command substitution.
function mage_ask() {
  local question="$1"
  local default="$2"
  local answer=""

  if [[ $MAGE_YES == 1 ]] && [[ -n "$default" ]]; then
    echo "$default"
    return
  fi

  if [[ -n "$default" ]]; then
    read -r -e -p "${question} (${default}): " answer || mage_no_answer "$question"
  else
    read -r -e -p "${question}: " answer || mage_no_answer "$question"
  fi

  echo "${answer:-$default}"
}

# Ask a yes/no question, where an empty answer takes the default of 'n' or 'y'
function mage_confirm() {
  local question="$1"
  local default="${2:-n}"
  local options="y/N"

  if [[ $default == "y" ]]; then
    options="Y/n"
  fi

  if [[ $MAGE_YES == 1 ]]; then
    [[ $default == "y" ]]
    return $?
  fi

  read -r -e -p "${question} [${options}] " || mage_no_answer "$question"

  if [[ -z "$REPLY" ]]; then
    [[ $default == "y" ]]
    return $?
  fi

  [[ $REPLY =~ ^[yY] ]]
}

# Echo a value from app/etc/env.php by its path, such as 'db/connection/default/dbname'.
# Uses the host php, so it fails quietly when php is not installed.
function mage_env_php() {
  if [[ ! -f app/etc/env.php ]] || ! command -v php &> /dev/null; then
    return 1
  fi

  php -r '
    $value = include "app/etc/env.php";
    foreach (explode("/", $argv[1]) as $key) {
      if (!is_array($value) || !isset($value[$key])) { exit(1); }
      $value = $value[$key];
    }
    if (is_scalar($value)) { echo $value; }
  ' -- "$1" 2> /dev/null
}

# Set the MAGE_DB_* settings from app/etc/env.php, keeping the current ones for what it lacks.
# The database name falls back to MAGE_DB_NAME, then the project folder.
function mage_env_php_db() {
  MAGE_DB_NAME="$(mage_env_php db/connection/default/dbname || echo "${MAGE_DB_NAME:-$(basename "$PWD")}")"
  MAGE_DB_HOST="$(mage_env_php db/connection/default/host || echo "$MAGE_DB_HOST")"
  MAGE_DB_USER="$(mage_env_php db/connection/default/username || echo "$MAGE_DB_USER")"
  MAGE_DB_PASS="$(mage_env_php db/connection/default/password || echo "$MAGE_DB_PASS")"
}

# Set MAGE_DB_ARGS to the connection arguments of mysql and mysqldump. The host
# can hold a port or a socket, such as localhost:3307 or localhost:/tmp/mysql.sock
function mage_db_args() {
  MAGE_DB_ARGS=(-h"${MAGE_DB_HOST%%:*}" -u"$MAGE_DB_USER")

  if [[ "$MAGE_DB_HOST" == *:/* ]]; then
    MAGE_DB_ARGS+=(--socket="${MAGE_DB_HOST#*:}")
  elif [[ "$MAGE_DB_HOST" == *:* ]]; then
    MAGE_DB_ARGS+=(-P"${MAGE_DB_HOST#*:}")
  fi
}

# Ask to type the name to confirm something that can not be undone
function mage_confirm_name() {
  local answer=""
  read -r -p "Type '${1}' to confirm: " answer || mage_no_answer "Type '${1}' to confirm"
  [[ "$answer" == "$1" ]]
}

# Stop when a question gets no answer, such as without a terminal for a script or
# agent, instead of quietly taking a default
function mage_no_answer() {
  echo "" >&2
  mage_error "No answer for: ${1}"
  mage_error "Run it in a terminal, or pass the answer as an option or -y, see docs/automation.md"
  exit 1
}

# Download a url to a given path, using curl or wget
function mage_download_file() {
  local url="$1"
  local target="$2"
  local temp="${target}.part"

  if command -v curl &> /dev/null; then
    curl -fsL "$url" -o "$temp"
  elif command -v wget &> /dev/null; then
    wget -qO "$temp" "$url"
  else
    mage_error "Neither curl nor wget is available"
    return 1
  fi

  if [[ ! -s "$temp" ]]; then
    rm -f "$temp"
    return 1
  fi

  mv "$temp" "$target"
}

# Echo the package name from a composer.json
function mage_composer_name() {
  if [[ -f "$1" ]]; then
    grep -E '"name"[[:space:]]*:' "$1" | head -n 1 | sed -E 's/.*"name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/'
  fi
}

# Convert a string to kebab-case, such as MyTheme to my-theme
function mage_kebab_case() {
  echo "$*" | sed 's/\([A-Z]\)/-\1/g' | tr '[:upper:]' '[:lower:]' | sed -e 's/^-*//' -e 's/-*$//' | tr -s '[:blank:]' '-'
}

function mage_lower_case() {
  echo "$*" | tr '[:upper:]' '[:lower:]'
}

# Ask for the vendor and name of a new theme or module, where 'Vendor/Name'
# works as one answer, and a name given as argument skips the question.
# A function can only echo one value, so the result is shared through
# MAGE_NEW_VENDOR, MAGE_NEW_NAME, MAGE_NEW_VENDOR_PKG and MAGE_NEW_NAME_PKG.
function mage_ask_vendor_name() {
  local label="$1"
  local name="$2"
  local vendor=""

  if [[ -z "$name" ]]; then
    name="$(mage_ask "${label} name (Vendor/Name)")" || return 1
  fi

  if [[ "$name" == */* ]]; then
    vendor="${name%%/*}"
    name="${name#*/}"
  fi

  if [[ -z "$vendor" ]]; then
    vendor="$(mage_ask "${label} vendor")" || return 1
  fi

  MAGE_NEW_VENDOR="$(echo "$vendor" | tr -d '[:blank:]')"
  MAGE_NEW_NAME="$(echo "$name" | tr -d '[:blank:]')"

  if [[ -z "$MAGE_NEW_VENDOR" ]] || [[ -z "$MAGE_NEW_NAME" ]]; then
    mage_error "The ${label} vendor and name can not be empty"
    return 1
  fi

  MAGE_NEW_VENDOR_PKG="$(mage_lower_case "$MAGE_NEW_VENDOR")"
  MAGE_NEW_NAME_PKG="$(mage_kebab_case "$MAGE_NEW_NAME")"
}

function mage_is_hyva_installed() {
  [[ -d vendor/hyva-themes/magento2-theme-module ]]
}

# Echo the packages in the composer.json key that contain any of the terms,
# case-insensitive and as plain text. Platform entries like php and ext-* have no slash.
function mage_composer_matches() {
  local key="$1"
  shift

  local patterns=()
  local term

  for term in "$@"; do
    patterns+=(-e "$term")
  done

  jq -r --arg key "$key" '.[$key] // {} | keys[] | select(contains("/"))' composer.json |
    grep -i -F "${patterns[@]}"
}

# Exit when jq is missing, the argument describes what needs it
function mage_require_jq() {
  if ! command -v jq &> /dev/null; then
    mage_error "$1 requires jq, install it with 'brew install jq' or your package manager"
    exit 1
  fi
}

# Make the theme, such as Hyva/default, the active theme where possible,
# otherwise point to the admin. Returns 1 when the theme was not set.
function mage_set_theme() {
  if [[ -d vendor/yireo/magento2-theme-commands ]]; then
    $MAGENTO_CLI theme:change "$1" && $MAGENTO_CLI cache:clean
    return
  fi

  mage_notice "Select the $1 theme in the admin, under Content, Design, Configuration"
  return 1
}

# Check whether the arguments ask for json output
function mage_wants_json() {
  [[ " $* " == *" --json "* ]]
}
