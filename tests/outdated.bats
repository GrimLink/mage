load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  COMPOSER_CLI="echo composer"
}

@test "writes the direct dependencies to composer-outdated.json, without the ignored packages" {
  run mage_cmd_outdated
  [ "$status" -eq 0 ]
  [ "$(cat composer-outdated.json)" = "composer outdated --direct --no-dev --ignore symfony/finder --ignore symfony/process --format json" ]
}

@test "shows them in the terminal with --terminal" {
  MAGE_OUTDATED_IGNORE=()

  run mage_cmd_outdated --terminal --minor-only
  [ "$output" = "composer outdated --direct --no-dev --minor-only" ]
  [ ! -e composer-outdated.json ]
}
