function mage_build() {
  local JOBS=4

  # Frontend variables with default values
  local LANGS="en_US nl_NL"
  local DEFAULT_ARGS="$LANGS $JOBS"
  local ARGS=""

  # Admin variables with default values
  local ADMIN_DEFAULT_ARGS="en_US $JOBS"
  local ADMIN_ARGS="en_US"

  for OPTION in "${@}"; do
    if [[ "$OPTION" =~ ^a: ]]; then
      # Extract argument after 'a:' (remove prefix)
      local STRIPPED_OPTION=${OPTION#a:}
      local ADMIN_ARGS="$ADMIN_ARGS $STRIPPED_OPTION"
    else
      local ARGS="$ARGS $OPTION"
    fi
  done

  # If language is not found in ARGS add the default
  if [[ $ARGS != *_* ]]; then
    local ARGS="$LANGS $ARGS"
  fi

  # If Jobs is not found in ARGS add the default
  if [[ "$ARGS" != *"-j"* ]] || [[ "$ARGS" != *"--jobs"* ]]; then
    local ARGS="$ARGS -j $JOBS"
  fi

  # If Jobs is not found in ADMIN_ARGS add the default
  if [[ "$ADMIN_ARGS" != *"-j"* ]] || [[ "$ADMIN_ARGS" != *"--jobs"* ]]; then
    local ADMIN_ARGS="$ADMIN_ARGS -j $JOBS"
  fi

  # If force is found in ARGS add it to both Frontend and Admin args
  if [[ "$ARGS" == *"-f"* ]] || [[ "$ARGS" == *"--force"* ]]; then
    local ADMIN_ARGS="$ADMIN_ARGS -f"
  fi

  # Deploy static content
  $MAGENTO_CLI setup:static-content:deploy -a adminhtml ${ADMIN_ARGS:-$ADMIN_DEFAULT_ARGS} &&
  $MAGENTO_CLI setup:static-content:deploy -a frontend ${ARGS:-$DEFAULT_ARGS}
}
