# Follow a log in var/log, debug by default, by its name with or without .log
function mage_cmd_log() {
  local name="${1:-debug}"
  local file="var/log/${name%.log}.log"

  if [[ ! -f "$file" ]]; then
    mage_error "${file} not found, the logs are:"
    mage_show_logs >&2
    exit 1
  fi

  tail -f -n 6 "$file"
}
