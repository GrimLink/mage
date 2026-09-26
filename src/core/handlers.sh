# Commands like add, clean and show pass their first argument to a handler.
# A handler registers as 'name|description' in the registry of its command,
# and is implemented as mage_<command>_<name>, with dashes as underscores.

# Check whether the name is in the given handler entries
function mage_handler_exists() {
  local name="$1"
  local entry
  shift

  for entry in "$@"; do
    if [[ "${entry%%|*}" == "$name" ]]; then
      return 0
    fi
  done

  return 1
}

# Run the handler of a command, such as mage_clean_sample_files for 'clean sample-files'
function mage_handler_run() {
  local command="$1"
  local name="$2"
  shift 2

  "mage_${command}_${name//-/_}" "$@"
}

# Print a help line for each of the given handler entries
function mage_handler_help() {
  local command="$1"
  local entry
  shift

  for entry in "$@"; do
    mage_help_cmd "${command} ${entry%%|*}" "${entry#*|}"
  done
}
