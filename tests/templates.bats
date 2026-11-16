load helper

function setup() {
  load_mage
  MAGE_VERSION="1.0.0"
  TEMPLATES="$(mage_config_dir)/templates"
  mkdir -p "$TEMPLATES"
  touch "${TEMPLATES}/old.json"
}

@test "echoes a template the synced templates have, without syncing" {
  function mage_sync_templates() { echo "sync"; }

  run mage_template_file old.json
  [ "$status" -eq 0 ]
  [ "$output" = "${TEMPLATES}/old.json" ]
}

@test "syncs the templates when they miss the file" {
  function mage_sync_templates() { touch "$1/new.json"; }

  run mage_template_file new.json
  [ "$status" -eq 0 ]
  [ "${lines[${#lines[@]}-1]}" = "${TEMPLATES}/new.json" ]
}

@test "fails when the synced templates still miss the file" {
  function mage_sync_templates() { return 0; }

  run mage_template_file missing.json
  [ "$status" -eq 1 ]
}

@test "fails when the sync fails" {
  function mage_sync_templates() { return 1; }

  run mage_template_file missing.json
  [ "$status" -eq 1 ]
}

@test "never syncs when running unbuilt" {
  MAGE_VERSION="dev"
  function mage_sync_templates() { echo "sync"; }

  run mage_template_file missing.json
  [ "$status" -eq 1 ]
  [[ "$output" != *"sync"* ]]
}
