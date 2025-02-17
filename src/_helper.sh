# Helper to format language inputs
function mage_lang_format_arguments() {
  formatted_args=""
  for arg in "$@"; do
    formatted_arg=$(tr '[a-z]' '[A-Z]' <<< "$arg")
    formatted_arg="${formatted_arg// /}"
    formatted_args="${formatted_args},${formatted_arg}"
  done
  formatted_args="${formatted_args:1}"
  echo "$formatted_args"
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

function get_composer_pkg_version() {
  echo -e $($COMPOSER_CLI show $1 | grep 'versions' | grep -o -E '\*\ .+' | awk '{print $2}' | cut -d',' -f1)
}
