load helper

function setup() {
  load_mage
}

@test "passes the arguments to magerun" {
  MAGERUN_CLI="echo magerun"

  run mage_cmd_run sys:info --format=json
  [ "$output" = "magerun sys:info --format=json" ]
}

@test "errors without magerun" {
  use_stub_bins

  run mage_cmd_run sys:info
  [ "$status" -eq 1 ]
  [[ "$output" == *"Magerun2 is not installed"* ]]
}
