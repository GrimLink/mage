MAGE_SHOW_HANDLERS+=("logs|Show the logs in var/log, by the name 'mage log' takes, with their size")

function mage_show_logs() {
  local file
  local found=0

  for file in var/log/*.log; do
    if [[ -f "$file" ]]; then
      found=1
      printf '%-30s %s\n' "$(basename "$file" .log)" "$(du -h "$file" | cut -f1)"
    fi
  done

  if [[ $found == 0 ]]; then
    mage_info "No logs in var/log"
  fi
}
