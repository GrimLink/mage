MAGE_ADD_HANDLERS+=("i18n|Collect the phrases of a module or theme into i18n/en_US.csv: [PATH], default the current folder")

# The path is resolved from the folder mage was called in, so it works from inside the module
function mage_add_i18n() {
  local path
  path="$(mage_resolve_path "${1:-.}")"

  if [[ ! -f "${path}/registration.php" ]] && ! mage_confirm "${1:-This folder} does not look like a module or theme, continue?"; then
    exit 1
  fi

  local temp="${path}/i18n/temp.csv"

  mkdir -p "${path}/i18n"
  $MAGENTO_CLI i18n:collect-phrases "$path" -o "$temp" || exit 1

  # Quote the lines Magento writes without quotes, then sort them
  sed -e 's/^\([^"].*\),\([^"].*\)$/"\1","\2"/' "$temp" | sort > "${path}/i18n/en_US.csv"
  rm -f "$temp"

  mage_check 0 "Written to ${path}/i18n/en_US.csv"
}
