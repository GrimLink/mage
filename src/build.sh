function mage_build() {
  local LANGS="en_US nl_NL"
  local JOBS=4
  local FORCE=""
  local DEFAULT_ARGS="$LANGS $JOBS"
  local ARGS=${@}

  # If language is not found in ARGS add the default
  if [[ $ARG != *_* ]]; then
    local ARGS="$LANGS $ARGS"
  fi

  # If Jobs is not found in ARGS add the default
  if [[ "$ARGS" != *"-j"* ]] || [[ "$ARGS" != *"--jobs"* ]]; then
    local ARGS="$ARGS -j $JOBS"
  fi

  # If force is found in ARGS add it to both adminhtml and frontend
  if [[ "$ARGS" == *"-f"* ]] || [[ "$ARGS" == *"--force"* ]]; then
    local FORCE="-f"
  fi

  # Deploy static content
  $MAGENTO_CLI setup:static-content:deploy -a adminhtml en_US ${FORCE} &&
  $MAGENTO_CLI setup:static-content:deploy -a frontend ${ARGS:-$DEFAULT_ARGS}
}
