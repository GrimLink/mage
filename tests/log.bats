load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  mkdir -p var/log
  echo "line" > var/log/system.log
  echo "line" > var/log/exception.log
  function tail() { echo "tail $*"; }
}

@test "follows the debug log by default" {
  touch var/log/debug.log

  run mage_cmd_log
  [ "$output" = "tail -f -n 6 var/log/debug.log" ]
}

@test "follows a log by its name, with or without .log" {
  run mage_cmd_log system
  [ "$output" = "tail -f -n 6 var/log/system.log" ]

  run mage_cmd_log system.log
  [ "$output" = "tail -f -n 6 var/log/system.log" ]
}

@test "lists the logs when one is missing" {
  run mage_cmd_log nope
  [ "$status" -eq 1 ]
  [[ "$output" == *"var/log/nope.log not found"* ]]
  [[ "$output" == *"exception"* ]]
  [[ "$output" == *"system"* ]]
}

@test "shows the logs" {
  run mage_cmd_show logs
  [[ "${lines[0]}" == "exception "* ]]
  [[ "${lines[1]}" == "system "* ]]
}

@test "cleans the logs, and only the logs" {
  touch var/log/keep.txt

  run mage_cmd_clean logs
  [ ! -e var/log/system.log ]
  [ ! -e var/log/exception.log ]
  [ -e var/log/keep.txt ]
}
