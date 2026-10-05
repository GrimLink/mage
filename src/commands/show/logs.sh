MAGE_SHOW_HANDLERS+=("logs|Show the logs in var/log, by the name 'mage log' takes, with their size, --json for json")

function mage_show_logs() {
  local file
  local lines=""

  for file in var/log/*.log; do
    if [[ -f "$file" ]]; then
      lines="${lines}$(basename "$file" .log)"$'\t'"$(wc -c < "$file" | tr -d ' ')"$'\t'"$(du -h "$file" | cut -f1)"$'\n'
    fi
  done

  if mage_wants_json "$@"; then
    mage_require_jq "Showing the logs as json"
    printf '%s' "$lines" | jq -R -s 'split("\n") | map(select(length > 0) | split("\t") | {name: .[0], bytes: (.[1] | tonumber)})'
    return
  fi

  if [[ -z "$lines" ]]; then
    mage_info "No logs in var/log"
    return
  fi

  local name
  local bytes
  local size

  while IFS=$'\t' read -r name bytes size; do
    printf '%-30s %s\n' "$name" "$size"
  done <<< "${lines%$'\n'}"
}
