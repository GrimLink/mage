load helper

function setup() {
  load_mage
}

@test "errors without an option, listing the handlers" {
  run mage_cmd_show
  [ "$status" -eq 1 ]
  [[ "$output" == *"show stores"* ]]
}

@test "errors on an unknown option" {
  run mage_cmd_show nope
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown show option 'nope'"* ]]
}

@test "shows the stores through magerun" {
  MAGERUN_CLI="echo magerun"

  run mage_cmd_show stores --format=json
  [ "$output" = "magerun sys:store:config:base-url:list --format txt --format=json" ]
}
