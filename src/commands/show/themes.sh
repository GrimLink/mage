MAGE_SHOW_HANDLERS+=("themes|Show the themes of the direct dependencies and app/design, with their parent")

function mage_show_themes() {
  mage_require_jq "Showing the themes"

  local themes
  themes="$(mage_show_components THEME "app/design" app/design/*/*/*/registration.php | sort -u)"

  if [[ -z "$themes" ]]; then
    mage_info "No themes found in the direct dependencies or app/design"
    return
  fi

  local name
  local source
  local dir
  local parent

  while IFS=$'\t' read -r name source dir; do
    parent=""
    if [[ -f "${dir}/theme.xml" ]]; then
      parent="$(tr '\n' ' ' < "${dir}/theme.xml" | grep -o '<parent>[^<]*</parent>' | sed -E 's/<\/?parent>//g')"
    fi

    if [[ -n "$parent" ]]; then
      printf '%-40s %-40s %s\n' "$name" "$source" "parent: ${parent}"
    else
      printf '%-40s %s\n' "$name" "$source"
    fi
  done <<< "$themes"
}
