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
