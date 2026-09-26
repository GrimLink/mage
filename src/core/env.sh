# Environments in order of priority, the first one detected wins.
# Each env/<name>.sh defines env_<name>_available, env_<name>_detect
# and env_<name>_apply, and may add any other hook, see env_call.
MAGE_ENVS="warden valet local"
MAGE_ENV="local"

# Echo the environment used by the current folder
function mage_env_detect() {
  local env

  for env in $MAGE_ENVS; do
    if "env_${env}_detect"; then
      echo "$env"
      return
    fi
  done

  echo "local"
}

# Echo the environments that are installed on this machine
function mage_env_available() {
  local env
  local available=()

  for env in $MAGE_ENVS; do
    if "env_${env}_available"; then
      available+=("$env")
    fi
  done

  echo "${available[*]}"
}

# Check whether the name is a known environment
function mage_env_exists() {
  [[ " $MAGE_ENVS " == *" $1 "* ]]
}

# Switch to the given environment
function mage_env_use() {
  if ! mage_env_exists "$1"; then
    mage_error "Unknown environment '$1', use one of: ${MAGE_ENVS}"
    exit 1
  fi

  MAGE_ENV="$1"
  env_call apply
}

function mage_env_init() {
  mage_env_use "$(mage_env_detect)"
}

# Run a hook of the current environment, falling back to the local one.
# A hook that neither defines is a no-op.
function env_call() {
  local hook="$1"
  shift

  if declare -F "env_${MAGE_ENV}_${hook}" > /dev/null; then
    "env_${MAGE_ENV}_${hook}" "$@"
  elif declare -F "env_local_${hook}" > /dev/null; then
    "env_local_${hook}" "$@"
  fi
}
