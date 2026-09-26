MAGE_SAMPLE_SETS+=("magento|The Luma sample data of Magento")

# sampledata:deploy picks the packages of the installed version through composer,
# so it works for every edition and inside a container
function mage_sample_magento() {
  $MAGENTO_CLI sampledata:deploy "$@" && $MAGENTO_CLI setup:upgrade || return 1

  # The sample data adds the Luma styles to the head, which any other theme would load too
  $MAGENTO_CLI config:set design/head/includes "" &> /dev/null

  if mage_is_hyva_installed; then
    mage_set_theme Hyva/default
  fi
}
