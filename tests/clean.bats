load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
}

@test "cleans all without arguments" {
  MAGE_CLEAN_ALL="varnish"
  function mage_clean_varnish() { echo "varnish"; }

  run mage_cmd_clean
  [ "$output" = "varnish" ]
}

@test "lists the handlers in the help" {
  run mage_cmd_clean help
  [ "$status" -eq 0 ]
  [[ "$output" == *"clean redis"* ]]
}

@test "errors on an unknown option" {
  run mage_cmd_clean nope
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown clean option 'nope'"* ]]
}

@test "runs a handler by its dashed name" {
  run mage_cmd_clean sample-files
  [ "$status" -eq 0 ]
  [ -d dev/sample-files ]
}

@test "runs the handlers of MAGE_CLEAN_ALL in order" {
  MAGE_CLEAN_ALL="varnish files"
  function mage_clean_files() { echo "files"; }
  function mage_clean_varnish() { echo "varnish"; }

  run mage_cmd_clean all
  [ "$output" = "$(printf 'varnish\nfiles')" ]
}

@test "empties the file folders, but keeps pub/static/.htaccess" {
  mkdir -p generated/code/Vendor pub/static/frontend var/cache/mage--0
  touch pub/static/.htaccess pub/static/deployed_version.txt

  run mage_cmd_clean files
  [ "$status" -eq 0 ]
  [ -d generated/code ]
  [ ! -e generated/code/Vendor ]
  [ ! -e pub/static/frontend ]
  [ ! -e pub/static/deployed_version.txt ]
  [ -f pub/static/.htaccess ]
  [ ! -e var/cache/mage--0 ]
}

@test "moves the sample files" {
  touch nginx.conf.sample package.json.sample composer.json

  mage_cmd_clean sample-files
  [ -f dev/sample-files/nginx.conf.sample ]
  [ -f dev/sample-files/package.json.sample ]
  [ -f composer.json ]
}

@test "cleans redis through the environment" {
  function env_local_clean_redis() { echo "local redis"; }

  run mage_cmd_clean redis
  [ "$output" = "local redis" ]
}
