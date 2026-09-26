MAGE_SAMPLE_SETS+=("hyva|The Koti sample data of Hyva, see https://docs.hyva.io/hyva-themes/getting-started/sample-data.html")

function mage_sample_hyva() {
  if ! mage_is_hyva_installed; then
    mage_error "The Hyva sample data needs the Hyva Theme, add it with 'mage add hyva'"
    return 1
  fi

  if [[ ! -d vendor/magento/module-sample-data ]]; then
    $COMPOSER_CLI require magento/module-sample-data || return 1
  fi

  local args=("$@")

  # Next to the Luma sample data, Koti needs to know whether to keep or replace it
  if mage_is_luma_sample_installed && [[ " $* " != *" --keep-luma "* ]] && [[ " $* " != *" --replace-luma "* ]]; then
    if mage_confirm "Replace the Luma sample data? This removes all products, orders and customers, otherwise Koti gets its own website"; then
      args+=(--replace-luma)
    else
      args+=(--keep-luma)
    fi
  fi

  $MAGENTO_CLI hyva:sampledata:deploy "${args[@]}" && $MAGENTO_CLI setup:upgrade
}
