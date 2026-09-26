MAGE_ADD_HANDLERS+=("sample|Add sample data, one set: magento (Luma) or hyva (Koti), asked when not given")

# Sample data sets register as 'name|description', see core/handlers.sh.
# Each installs its data, runs setup:upgrade and anything after it needs.
MAGE_SAMPLE_SETS=()

# Install one sample data set, further arguments go to its deploy command
function mage_add_sample() {
  local set="$1"
  shift

  local names=""
  local entry

  for entry in "${MAGE_SAMPLE_SETS[@]}"; do
    names="${names:+$names }${entry%%|*}"
  done

  if [[ -z "$set" ]]; then
    local default="magento"
    if mage_is_hyva_installed; then
      default="hyva"
    fi

    set="$(mage_ask "Sample data [${names}]" "$default")"
  fi

  if ! mage_handler_exists "$set" "${MAGE_SAMPLE_SETS[@]}"; then
    mage_error "Unknown sample data '${set}', use one of: ${names}"
    exit 1
  fi

  mage_handler_run sample "$set" "$@" || exit 1

  $MAGENTO_CLI indexer:reindex
  $MAGENTO_CLI cache:clean
}

function mage_is_luma_sample_installed() {
  [[ -d vendor/magento/module-catalog-sample-data ]]
}
