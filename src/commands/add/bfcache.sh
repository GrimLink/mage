MAGE_ADD_HANDLERS+=("bfcache|Add the BFCache compatibility patches")

MAGE_BFCACHE_PATCH_REPO="https://github.com/GrimLink/magento-patch-bfcache"

function mage_add_bfcache() {
  if [[ $# -gt 0 ]]; then
    mage_error "No options are expected for 'add bfcache'"
    exit 1
  fi

  mage_add_patch "$MAGE_BFCACHE_PATCH_REPO"
}
