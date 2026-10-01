MAGE_SAMPLE_SETS+=("magento|The Luma sample data of Magento")

# sampledata:deploy picks the packages of the installed version through composer,
# so it works for every edition and inside a container
function mage_sample_magento() {
  $MAGENTO_CLI sampledata:deploy "$@" && $MAGENTO_CLI setup:upgrade || return 1

  if mage_is_hyva_installed; then
    mage_set_theme Hyva/default
  fi
}
