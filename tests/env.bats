load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
}

@test "uses local when nothing is installed" {
  use_stub_bins

  [ "$(mage_env_detect)" = "local" ]
  [ "$(mage_env_available)" = "local" ]
}

@test "uses valet when valet is installed" {
  use_stub_bins valet

  [ "$(mage_env_detect)" = "valet" ]
}

@test "uses warden for a warden project, over valet" {
  use_stub_bins valet warden
  echo "WARDEN_ENV_NAME=project" > .env

  [ "$(mage_env_detect)" = "warden" ]
  [ "$(mage_env_available)" = "warden valet local" ]
}

@test "uses ddev for a ddev project, over valet" {
  use_stub_bins valet ddev
  mkdir .ddev
  touch .ddev/config.yaml

  [ "$(mage_env_detect)" = "ddev" ]
  [ "$(mage_env_available)" = "ddev valet local" ]
}

@test "uses local inside the ddev container" {
  use_stub_bins
  mkdir .ddev
  touch .ddev/config.yaml

  [ "$(mage_env_detect)" = "local" ]
}

@test "applies the ddev domain and services" {
  mage_env_use ddev

  [ "$MAGENTO_CLI" = "ddev magento" ]
  [ "$MAGE_DOMAIN" = "ddev.site" ]
  [ "$MAGE_DB_NAME" = "db" ]
}

@test "sets up sessions in its own redis for ddev" {
  mage_env_use ddev
  env_call setup_session_args

  [[ "${MAGE_SETUP_SESSION_ARGS[*]}" == "--session-save=redis"* ]]
}

@test "ignores warden without its .env" {
  use_stub_bins warden

  [ "$(mage_env_detect)" = "local" ]
}

@test "uses local inside the warden container" {
  use_stub_bins
  echo "WARDEN_ENV_NAME=project" > .env

  [ "$(mage_env_detect)" = "local" ]
}

@test "applies the warden commands" {
  mage_env_use warden

  [ "$MAGE_ENV" = "warden" ]
  [ "$MAGENTO_CLI" = "warden env exec php-fpm bin/magento" ]
  [ "$MAGE_DB_HOST" = "db" ]
}

@test "sets up sessions in its own redis for warden" {
  mage_env_use warden
  env_call setup_session_args

  [[ "${MAGE_SETUP_SESSION_ARGS[*]}" == "--session-save=redis"* ]]
}

@test "sets up sessions in the database for local and valet, dropped with it on nuke" {
  mage_env_use local
  env_call setup_session_args
  [ "${MAGE_SETUP_SESSION_ARGS[*]}" = "--session-save=db" ]

  mage_env_use valet
  env_call setup_session_args
  [ "${MAGE_SETUP_SESSION_ARGS[*]}" = "--session-save=db" ]
}

@test "falls back to the local hook" {
  function env_local_example() {
    echo "local $1"
  }

  mage_env_use valet
  [ "$(env_call example arg)" = "local arg" ]
}

@test "ignores a hook no environment defines" {
  mage_env_use valet
  run env_call does_not_exist
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "rejects an unknown environment" {
  run mage_env_use nope
  [ "$status" -eq 1 ]
}
