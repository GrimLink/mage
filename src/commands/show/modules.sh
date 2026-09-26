MAGE_SHOW_HANDLERS+=("modules|Show the modules of the direct dependencies and app/code")

function mage_show_modules() {
  mage_require_jq "Showing the modules"

  local modules
  modules="$(mage_show_components MODULE "app/code" app/code/*/*/registration.php | sort -u)"

  if [[ -z "$modules" ]]; then
    mage_info "No modules found in the direct dependencies or app/code"
    return
  fi

  local name
  local source
  local dir
  local status

  while IFS=$'\t' read -r name source dir; do
    status=""
    if grep -q "'${name}' => 0" app/etc/config.php 2> /dev/null; then
      status=" ${YELLOW}(disabled)${RESET}"
    fi

    printf '%-40s %s%s\n' "$name" "$source" "$status"
  done <<< "$modules"
}
