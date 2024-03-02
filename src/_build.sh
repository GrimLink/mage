function mage_build() {
  local jobs=4

  # Frontend variables with default values
  local langs="en_US nl_NL"
  local default_args="$langs $jobs"
  local args=""

  # Admin variables with default values
  local admin_default_args="en_US $jobs"
  local admin_args="en_US"

  for option in "${@}"; do
    if [[ "$option" =~ ^a: ]]; then
      # Extract argument after 'a:' (remove prefix)
      local stripped_option=${option#a:}
      local admin_args="$admin_args $stripped_option"
    else
      local args="$args $option"
    fi
  done

  # If language is not found in ARGS add the default
  if [[ $args != *_* ]]; then
    local args="$langs $args"
  fi

  # If Jobs is not found in ARGS add the default
  if [[ "$args" != *"-j"* ]] || [[ "$args" != *"--jobs"* ]]; then
    local args="$args -j $jobs"
  fi

  # If Jobs is not found in ADMIN_ARGS add the default
  if [[ "$admin_args" != *"-j"* ]] || [[ "$admin_args" != *"--jobs"* ]]; then
    local admin_args="$admin_args -j $jobs"
  fi

  # If force is found in ARGS add it to both Frontend and Admin args
  if [[ "$args" == *"-f"* ]] || [[ "$args" == *"--force"* ]]; then
    local admin_args="$admin_args -f"
  fi

  # Deploy static content
  $MAGENTO_CLI setup:static-content:deploy -a adminhtml ${admin_args:-$admin_default_args} &&
  $MAGENTO_CLI setup:static-content:deploy -a frontend ${args:-$default_args}
}
