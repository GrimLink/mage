MAGE_SHOW_HANDLERS+=("modules|Show the modules of the direct dependencies and app/code, --json for json")

function mage_show_modules() {
  mage_require_jq "Showing the modules"

  local modules
  modules="$(mage_show_components MODULE "app/code" app/code/*/*/registration.php | sort -u)"

  local name
  local source
  local dir
  local enabled

  # One 'name<tab>source<tab>enabled' line per module
  local lines=""
  while IFS=$'\t' read -r name source dir; do
    if [[ -z "$name" ]]; then
      continue
    fi

    enabled=1
    if grep -q "'${name}' => 0" app/etc/config.php 2> /dev/null; then
      enabled=0
    fi

    lines="${lines}${name}"$'\t'"${source}"$'\t'"${enabled}"$'\n'
  done <<< "$modules"

  if mage_wants_json "$@"; then
    printf '%s' "$lines" | jq -R -s 'split("\n") | map(select(length > 0) | split("\t") | {name: .[0], source: .[1], enabled: (.[2] == "1")})'
    return
  fi

  if [[ -z "$lines" ]]; then
    mage_info "No modules found in the direct dependencies or app/code"
    return
  fi

  while IFS=$'\t' read -r name source enabled; do
    if [[ "$enabled" == 0 ]]; then
      printf '%-40s %s %s\n' "$name" "$source" "${YELLOW}(disabled)${RESET}"
    else
      printf '%-40s %s\n' "$name" "$source"
    fi
  done <<< "${lines%$'\n'}"
}
