MAGE_SHOW_HANDLERS+=("modules|Show the modules of the direct dependencies and app/code")

# Like outdated, only the direct dependencies count, so the modules
# they pull in, such as those of Magento itself, stay out
function mage_show_modules() {
  mage_require_jq "Showing the modules"

  local modules
  modules="$(mage_show_modules_list | sort -u)"

  if [[ -z "$modules" ]]; then
    mage_info "No modules found in the direct dependencies or app/code"
    return
  fi

  local name
  local source
  local status

  while IFS=$'\t' read -r name source; do
    status=""
    if grep -q "'${name}' => 0" app/etc/config.php 2> /dev/null; then
      status=" ${YELLOW}(disabled)${RESET}"
    fi

    printf '%-40s %s%s\n' "$name" "$source" "$status"
  done <<< "$modules"
}

# Echo 'module<tab>source' for every module of a direct dependency or in app/code
function mage_show_modules_list() {
  local package
  local file
  local name

  while IFS= read -r package; do
    if [[ ! -d "vendor/${package}" ]]; then
      continue
    fi

    # The trailing slash follows the symlink of a path repository package
    while IFS= read -r file; do
      name="$(mage_module_name "$file")"
      if [[ -n "$name" ]]; then
        printf '%s\t%s\n' "$name" "$package"
      fi
    done < <(find "vendor/${package}/" -maxdepth 3 -name registration.php -not -path "*/node_modules/*")
  done < <(jq -r '(.require // {}), (."require-dev" // {}) | keys[] | select(contains("/"))' composer.json)

  for file in app/code/*/*/registration.php; do
    if [[ -f "$file" ]]; then
      name="$(mage_module_name "$file")"
      printf '%s\t%s\n' "$name" "app/code"
    fi
  done
}

# Echo the module name a registration.php registers, nothing for a theme or library
function mage_module_name() {
  tr '\n' ' ' < "$1" |
    grep -o "ComponentRegistrar::MODULE,[[:space:]]*['\"][A-Za-z0-9_]*['\"]" |
    head -n 1 |
    sed -E "s/.*['\"]([A-Za-z0-9_]+)['\"]$/\1/"
}
