# Echo the mage config folder, and create it when missing
function mage_config_dir() {
  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/mage"
  mkdir -p "$config_dir"
  echo "$config_dir"
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
    echo "Neither curl nor wget is available"
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
  local temp_dir=$(mktemp -d)
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
  local templates_dir="$(mage_config_dir)/templates"

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
  local file="$(mage_templates_dir)/$1"

  if [[ ! -f "$file" ]]; then
    return 1
  fi

  echo "$file"
}

# Copy a template folder to a destination,
# where each NAME=value argument replaces {{NAME}} in the copied files
function mage_copy_template() {
  local template="$1"
  local dest="$2"
  shift 2

  local template_dir="$(mage_templates_dir)/${template}"

  if [[ ! -d "$template_dir" ]]; then
    echo "Could not get the '${template}' template from ${MAGE_TEMPLATES_ARCHIVE}"
    return 1
  fi

  mkdir -p "$dest"
  cp -R "${template_dir}/." "$dest"

  local file
  local content
  local pair

  while IFS= read -r -d '' file; do
    content="$(cat "$file")"

    for pair in "$@"; do
      content="${content//\{\{${pair%%=*}\}\}/${pair#*=}}"
    done

    printf '%s\n' "$content" > "$file"
  done < <(find "$dest" -type f -print0)
}

# Creates a file/folder and echo the contents in one command
function mage_make_file() {
  touch $1

  if [[ $2 == "rsync" ]]; then
    if [[ -d $3 ]]; then
      rsync -ah ${3}/ ${1} --exclude node_modules
    else
      echo -e "The folder '${3}' does not exists"
    fi
  else
    echo -e $2 >> $1
  fi
}

# Convert string to kebab-case
function mage_kebab_case() {
  echo "${@}" | sed 's/\([A-Z]\)/-\1/g' | tr '[:upper:]' '[:lower:]' | sed -e 's/^-*//' -e 's/-*$//' | tr -s '[:blank:]' '-'
}

# Convert string to lowercase
function mage_lower_case() {
  echo "${@}" | tr '[:upper:]' '[:lower:]'
}

# Ask a yes/no question, where an empty answer takes the default of 'n' or 'y'.
# The prompt goes to stderr, so this stays usable inside a command substitution.
function mage_confirm() {
  local question="$1"
  local default="${2:-n}"
  local options="y/N"

  if [[ $default == "y" ]]; then
    options="Y/n"
  fi

  read -e -p "${question} [${options}] "
  echo "" >&2

  if [[ -z "$REPLY" ]]; then
    [[ $default == "y" ]]
    return $?
  fi

  [[ $REPLY =~ ^[yY] ]]
}

# Get the Magento 2 Base Url
function get_mage_base_uri() {
  local baseuri="$($MAGENTO_CLI config:show web/secure/base_url)"
  if [[ -z "${baseuri}" ]]; then
    local baseuri="$($MAGENTO_CLI config:show web/unsecure/base_url)"
  fi
  echo $baseuri
}

# Get specific Magento 2 Store Url
function get_mage_store_uri() {
  local store_url=""

  if [[ -n "$MAGERUN_CLI" ]]; then
    if [[ "$1" == "admin" ]]; then
      store_url=$($MAGERUN_CLI sys:store:config:base-url:list --format csv | grep 1 -m 1 | head -1 | cut -d ',' -f3)
    else
      store_url=$($MAGERUN_CLI sys:store:config:base-url:list --format csv | grep $1 | cut -d ',' -f3)
    fi
  else
    store_url=$(get_mage_base_uri)
  fi

  echo $store_url
}

# Get the admin path based on the app/etc/env.php
function get_mage_admin_path_env() {
  php -r '
    $array = include("app/etc/env.php");
    if (isset($array["backend"]["frontName"])) { echo $array["backend"]["frontName"]; }
  ' 2>/dev/null
}

# Get the Magento admin path
function get_mage_admin_path() {
  local admin_path=""
  local admin_custom_path=$($MAGENTO_CLI config:show admin/url/use_custom_path)

  if [[ $admin_custom_path == "1" ]]; then
    local admin_path=$($MAGENTO_CLI config:show admin/url/custom_path)
  else
    local admin_path=$(get_mage_admin_path_env)
  fi

  echo $admin_path
}

function get_composer_pkg_version() {
  echo -e $($COMPOSER_CLI show $1 | grep 'versions' | grep -o -E '\* .+' | awk '{print $2}' | cut -d',' -f1)
}

function is_hyva_installed() {
  $COMPOSER_CLI show hyva-themes/magento2-theme-module > /dev/null 2>&1
}

function is_theme_cli_installed() {
  $COMPOSER_CLI show yireo/magento2-theme-commands > /dev/null 2>&1
}

function get_mage_modules() {
  php -r '
    $config = include "app/etc/config.php";
    if (isset($config["modules"])) {
      $modules = array_filter(array_keys($config["modules"]), function($module) {
        return strpos($module, "Magento_") === false && strpos($module, "PayPal_Braintree") === false;
      });
      echo implode("\n", $modules);
    }
  ' 2>/dev/null
}

function get_mage_module_count() {
  echo $(get_mage_modules | wc -l)
}

function check_has_magerun() {
  if [[ -z "$MAGERUN_CLI" ]]; then
    echo "Magerun2 is not installed or incompatible with current PHP version"
    exit 1
  fi
}

function mage_add_valet_store() {
  local store_name=${1:-'store'}
  local store_code=${2:-'default'}
  local is_commented=${3:-false}

  if [ "$is_commented" = true ]; then
    echo -e "\t// '${store_name}' => ["
    echo -e "\t// \t'MAGE_RUN_CODE' => '${store_code}',"
    echo -e "\t// \t'MAGE_RUN_TYPE' => 'store',"
    echo -e "\t// ],"
  else
    echo -e "\t'${store_name}' => ["
    echo -e "\t\t'MAGE_RUN_CODE' => '${store_code}',"
    echo -e "\t\t'MAGE_RUN_TYPE' => 'store',"
    echo -e "\t],"
  fi
}

function mage_cleanup_sample_files() {
  mkdir -p dev/sample-files
  find . -maxdepth 1 -type f -name "*.sample" -exec mv {} dev/sample-files/ \;
  echo "All files ending with '.sample' have been moved to 'dev/sample-files'"
}

function get_all_composer_pkgs() {
  echo $($COMPOSER_CLI show --name-only --direct | grep -E "$@")
}

function get_composer_pkg_name_from_file() {
  local file_path="$1"
  if [[ -f "$file_path" ]]; then
    grep -E '"name"[[:space:]]*:' "$file_path" | head -n 1 | sed -E 's/.*"name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/'
  fi
}
