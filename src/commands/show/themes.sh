MAGE_SHOW_HANDLERS+=("themes|Show the themes of the direct dependencies and app/design, with their parent, --json for json")

function mage_show_themes() {
  mage_require_jq "Showing the themes"

  local themes
  themes="$(mage_show_components THEME "app/design" app/design/*/*/*/registration.php | sort -u)"

  local name
  local source
  local dir
  local parent

  # One 'name<tab>source<tab>parent' line per theme
  local lines=""
  while IFS=$'\t' read -r name source dir; do
    if [[ -z "$name" ]]; then
      continue
    fi

    parent=""
    if [[ -f "${dir}/theme.xml" ]]; then
      parent="$(tr '\n' ' ' < "${dir}/theme.xml" | grep -o '<parent>[^<]*</parent>' | sed -E 's/<\/?parent>//g')"
    fi

    lines="${lines}${name}"$'\t'"${source}"$'\t'"${parent}"$'\n'
  done <<< "$themes"

  if mage_wants_json "$@"; then
    printf '%s' "$lines" | jq -R -s 'split("\n") | map(select(length > 0) | split("\t") | {name: .[0], source: .[1], parent: (if (.[2] // "") == "" then null else .[2] end)})'
    return
  fi

  if [[ -z "$lines" ]]; then
    mage_info "No themes found in the direct dependencies or app/design"
    return
  fi

  while IFS=$'\t' read -r name source parent; do
    if [[ -n "$parent" ]]; then
      printf '%-40s %-40s %s\n' "$name" "$source" "parent: ${parent}"
    else
      printf '%-40s %s\n' "$name" "$source"
    fi
  done <<< "${lines%$'\n'}"
}
