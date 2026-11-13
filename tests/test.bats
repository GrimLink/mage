load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"

  # A mage that echoes the command, and fails 'mage fail'
  MAGE_SELF="${BATS_TEST_TMPDIR}/fake-mage"
  printf '#!/bin/sh\necho "mage ran $*"\n[ "$1" != "fail" ]\n' > "$MAGE_SELF"
  chmod +x "$MAGE_SELF"
}

@test "runs each action as a shell command, with mage as itself" {
  echo '{ "test": ["mage lint -s", "echo one | tr o O"] }' > mage.config.json

  run mage_cmd_test
  [ "$status" -eq 0 ]
  [[ "$output" == *"mage ran lint -s"* ]]
  [[ "$output" == *"One"* ]]
  [[ "$output" == *"All tests passed"* ]]
}

@test "runs every action and lists those that failed" {
  echo '{ "test": ["mage fail", "echo after", "false"] }' > mage.config.json

  run mage_cmd_test
  [ "$status" -eq 1 ]
  [[ "$output" == *"after"* ]]
  [[ "${lines[${#lines[@]}-2]}" == *"mage fail" ]]
  [[ "${lines[${#lines[@]}-1]}" == *"false" ]]
  [[ "$output" != *"All tests passed"* ]]
}

@test "an action reading stdin does not take the next actions" {
  echo '{ "test": ["cat > /dev/null", "echo second"] }' > mage.config.json

  run mage_cmd_test < /dev/null
  [[ "$output" == *"second"* ]]
}

@test "creates the mage.config.json from the template with -y" {
  mkdir app

  run mage_cmd_test -y
  [[ "$output" == *"Created mage.config.json"* ]]
  [[ "$output" == *"mage ran lint"* ]]
  cmp mage.config.json "${MAGE_REPO}/templates/mage.config.json"
}

@test "runs nothing when an action changes files" {
  echo '{ "test": ["mage lint app/code", "find app -name x | xargs rm", "echo x > out.txt", "git clean -fd"] }' > mage.config.json

  run mage_cmd_test
  [ "$status" -eq 1 ]
  [[ "$output" == *"never runs actions that remove, move or write files"* ]]
  [[ "$output" == *"xargs rm"* ]]
  [[ "$output" == *"echo x > out.txt"* ]]
  [[ "$output" == *"git clean -fd"* ]]
  [[ "$output" != *"mage ran"* ]]
  [ ! -e out.txt ]
}

@test "allows redirects to /dev/null and php arrows" {
  echo '{ "test": ["echo a > /dev/null 2>&1", "echo b &> /dev/null", "echo \"$a->b, [1 => 2]\""] }' > mage.config.json

  run mage_cmd_test
  [ "$status" -eq 0 ]
  [[ "$output" == *"All tests passed"* ]]
}

@test "the templates have no blocked actions" {
  local template

  for template in "${MAGE_REPO}"/templates/mage*.config.json; do
    [ -z "$(jq -r --arg re "$(mage_test_blocked_pattern)" '.test[] | select(test($re))' "$template")" ]
  done
}

@test "creates nothing without an answer" {
  run mage_cmd_test < /dev/null
  [ "$status" -ne 0 ]
  [ ! -e mage.config.json ]
}

@test "errors on a test that is not a list of commands" {
  echo '{ "test": "mage lint" }' > mage.config.json

  run mage_cmd_test
  [ "$status" -eq 1 ]
  [[ "$output" == *"should be a list of shell commands"* ]]
}
