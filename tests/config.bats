load helper

function setup() {
  export XDG_CONFIG_HOME="${BATS_TEST_TMPDIR}/config"
  CONFIG_DIR="${XDG_CONFIG_HOME}/mage"
  mkdir -p "$CONFIG_DIR"
  chmod 755 "$CONFIG_DIR"
  echo 'MAGE_DOMAIN="example"' > "${CONFIG_DIR}/config"
  chmod 600 "${CONFIG_DIR}/config"
}

# Load mage in its own shell, as an unsafe config stops it
function load_in_shell() {
  bash -c 'source "$1" && echo "domain=$MAGE_DOMAIN"' _ "${MAGE_REPO}/src/mage.sh"
}

@test "loads a config only you can change" {
  run load_in_shell
  [ "$status" -eq 0 ]
  [ "$output" = "domain=example" ]
}

@test "refuses a config others can change" {
  chmod 666 "${CONFIG_DIR}/config"

  run load_in_shell
  [ "$status" -eq 1 ]
  [[ "$output" == *"Not loading"*"chmod 600"* ]]
  [[ "$output" != *"domain="* ]]
}

@test "refuses a config folder others can change" {
  chmod 777 "$CONFIG_DIR"

  run load_in_shell
  [ "$status" -eq 1 ]
}

@test "saves to a new config readable by you only" {
  rm "${CONFIG_DIR}/config"
  load_mage

  mage_config_save MAGE_VAR_PROJECT 'my $(project)' 2> /dev/null

  [ -n "$(find "${CONFIG_DIR}/config" -perm 600)" ]
  source "${CONFIG_DIR}/config"
  [ "$MAGE_VAR_PROJECT" = 'my $(project)' ]
}
