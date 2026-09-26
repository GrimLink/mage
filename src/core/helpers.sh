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

  if [[ -n "$default" ]]; then
    read -r -e -p "${question} (${default}): " answer
  else
    read -r -e -p "${question}: " answer
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

  read -r -e -p "${question} [${options}] "

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

# Sync the templates folder into the mage config folder.
# The whole folder is replaced at once, so a failed sync
# keeps the previous templates usable.
function mage_sync_templates() {
  local target="$1"
  local temp_dir
  temp_dir="$(mktemp -d)"
  local archive="${temp_dir}/templates.tar.gz"

  if mage_download_file "$MAGE_TEMPLATES_ARCHIVE" "$archive" &&
    tar -xzf "$archive" -C "$temp_dir" --strip-components=1 &> /dev/null &&
    [[ -d "$temp_dir/templates" ]]; then
    rm -rf "$target"
    mv "$temp_dir/templates" "$target"
    touch "$target"
  fi

  rm -rf "$temp_dir"
}

# Echo the folder with the mage templates, refreshed when older than 30 days
function mage_templates_dir() {
  local templates_dir
  templates_dir="$(mage_config_dir)/templates"

  if [[ ! -d "$templates_dir" ]] || [[ -n "$(find "$templates_dir" -maxdepth 0 -mtime +30)" ]]; then
    mage_sync_templates "$templates_dir"
  fi

  if [[ ! -d "$templates_dir" ]]; then
    return 1
  fi

  echo "$templates_dir"
}

# Echo the path to a single template file
function mage_template_file() {
  local file
  file="$(mage_templates_dir)/$1"

  if [[ ! -f "$file" ]]; then
    return 1
  fi

  echo "$file"
}

# Echo the package name from a composer.json
function mage_composer_name() {
  if [[ -f "$1" ]]; then
    grep -E '"name"[[:space:]]*:' "$1" | head -n 1 | sed -E 's/.*"name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/'
  fi
}
