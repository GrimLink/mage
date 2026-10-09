MAGE_ADD_HANDLERS+=("storeinfo|Add the Siteation StoreInfo modules")

# The package list lives in its composer fragment, so it can change without a rebuild
function mage_add_storeinfo() {
  if [[ $# -gt 0 ]]; then
    mage_error "No options are expected for 'add storeinfo'"
    exit 1
  fi

  local file
  file="$(mage_template_file "composer-storeinfo.json")"

  if [[ -z "$file" ]]; then
    mage_error "Could not get the 'composer-storeinfo.json' template from ${MAGE_TEMPLATES_ARCHIVE}"
    exit 1
  fi

  mage_add_json "$file" || exit 1
  $MAGENTO_CLI setup:upgrade
}
