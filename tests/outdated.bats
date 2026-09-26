load helper

function setup() {
  load_mage
  COMPOSER_CLI="echo composer"
}

@test "shows the direct dependencies, without the ignored packages" {
  run mage_cmd_outdated
  [ "$output" = "composer outdated --direct --no-dev --ignore symfony/finder --ignore symfony/process" ]
}

@test "passes further arguments to composer" {
  MAGE_OUTDATED_IGNORE=()

  run mage_cmd_outdated --format=json
  [ "$output" = "composer outdated --direct --no-dev --format=json" ]
}
