MAGE_ADD_HANDLERS+=("sample|Add sample data, one set: magento (Luma) or hyva (Koti), asked when not given, -y takes the defaults")

# Sample data sets register as 'name|description', see core/handlers.sh.
# Each installs its data, runs setup:upgrade and anything after it needs,
# the head styles, reindex and cache clean follow for every set.
MAGE_SAMPLE_SETS=()

# Install one sample data set, further arguments go to its deploy command
function mage_add_sample() {
  local set=""
  local args=()
  local arg

  for arg in "$@"; do
    case "$arg" in
      -y | --yes) MAGE_YES=1 ;;
      -*) args+=("$arg") ;;
      *)
        if [[ -z "$set" ]]; then
          set="$arg"
        else
          args+=("$arg")
        fi
        ;;
    esac
  done

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

    set="$(mage_ask "Sample data [${names}]" "$default")" || exit 1
  fi

  if ! mage_handler_exists "$set" "${MAGE_SAMPLE_SETS[@]}"; then
    mage_error "Unknown sample data '${set}', use one of: ${names}"
    exit 1
  fi

  mage_handler_run sample "$set" "${args[@]}" || exit 1

  # Both sets add their styles to the page head, which any other theme would load too
  if mage_confirm "Clear the styles the sample data adds to the page head (design/head/includes)?" "y"; then
    $MAGENTO_CLI config:set design/head/includes "" > /dev/null && mage_check 0 "Cleared design/head/includes"
  fi

  $MAGENTO_CLI indexer:reindex
  $MAGENTO_CLI cache:clean
}

function mage_is_luma_sample_installed() {
  [[ -d vendor/magento/module-catalog-sample-data ]]
}
