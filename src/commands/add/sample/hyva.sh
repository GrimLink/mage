MAGE_SAMPLE_SETS+=("hyva|The Koti sample data of Hyva, see https://docs.hyva.io/hyva-themes/getting-started/sample-data.html")

function mage_sample_hyva() {
  if ! mage_is_hyva_installed; then
    mage_error "The Hyva sample data needs the Hyva Theme, add it with 'mage add hyva'"
    return 1
  fi

  # Without the Hyva packagist repository of a license, such as Hyva from the GitLab
  # or from package-source, the Koti packages come from their GitLab repositories
  if ! mage_hyva_has_license; then
    local file
    file="$(mage_template_file "composer-hyva-sample-dev.json")"

    if [[ -z "$file" ]]; then
      mage_error "Could not get the 'composer-hyva-sample-dev.json' template from ${MAGE_TEMPLATES_ARCHIVE}"
      return 1
    fi

    mage_add_json "$file" || return 1
  fi

  local args=("$@")

  # Next to the Luma sample data, Koti needs to know whether to keep or replace it
  if mage_is_luma_sample_installed && [[ " $* " != *" --keep-luma "* ]] && [[ " $* " != *" --replace-luma "* ]]; then
    if [[ $MAGE_YES != 1 ]] && mage_confirm "Replace the Luma sample data? This removes all products, orders and customers, otherwise Koti gets its own website"; then
      args+=(--replace-luma)
    else
      args+=(--keep-luma)
    fi
  fi

  $MAGENTO_CLI hyva:sampledata:deploy "${args[@]}" && $MAGENTO_CLI setup:upgrade
}

# Check whether composer.json has the Hyva packagist repository that comes with a license
function mage_hyva_has_license() {
  mage_require_jq "The Hyva sample data"
  jq -e '[.repositories // {} | .[] | .url? // empty | select(startswith("https://hyva-themes.repo.packagist.com/"))] | length > 0' composer.json &> /dev/null
}
