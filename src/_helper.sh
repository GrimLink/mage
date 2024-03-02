# Helper to format language inputs
function format_arguments() {
  formatted_args=""
  for arg in "$@"; do
    formatted_arg=$(tr '[a-z]' '[A-Z]' <<< "$arg")
    formatted_arg="${formatted_arg// /}"
    formatted_args="${formatted_args},${formatted_arg}"
  done
  formatted_args="${formatted_args:1}"
  echo "$formatted_args"
}

# Get the Magento 2 Base Url
function get_mage_base_uri() {
  local baseuri="$($MAGENTO_CLI config:show web/secure/base_url)"
  if [[ -z "${baseuri}" ]]; then
    local baseuri="$($MAGENTO_CLI config:show web/unsecure/base_url)"
  fi
  echo $baseuri
}
