# The templates are synced to the mage config folder on first use and by
# self-update, so they are available offline and never fetched per command

# Replace the templates in the target folder with those from the latest release.
# The whole folder is replaced at once, so a failed sync keeps the previous templates.
function mage_sync_templates() {
  local target="$1"
  local temp_dir
  temp_dir="$(mktemp -d)"
  local archive="${temp_dir}/templates.tar.gz"
  local status=1

  if mage_download_file "$MAGE_TEMPLATES_ARCHIVE" "$archive" &&
    tar -xzf "$archive" -C "$temp_dir" --strip-components=1 &> /dev/null &&
    [[ -d "$temp_dir/templates" ]]; then
    rm -rf "$target"
    mv "$temp_dir/templates" "$target"
    status=0
  fi

  rm -rf "$temp_dir"
  return $status
}

# Echo the templates folder. Running unbuilt, that is the one in the repository.
function mage_templates_dir() {
  if [[ "$MAGE_VERSION" == "dev" ]]; then
    echo "$(dirname "$MAGE_SRC")/templates"
    return
  fi

  local templates_dir
  templates_dir="$(mage_config_dir)/templates"

  if [[ ! -d "$templates_dir" ]]; then
    mage_sync_templates "$templates_dir"
  fi

  if [[ ! -d "$templates_dir" ]]; then
    return 1
  fi

  echo "$templates_dir"
}

# Echo the path to a single template file
function mage_template_file() {
  local file
  file="$(mage_templates_dir)/$1"

  if [[ ! -f "$file" ]]; then
    return 1
  fi

  echo "$file"
}

# Copy a template folder to a destination,
# where each NAME=value argument replaces {{NAME}} in the copied files
function mage_copy_template() {
  local template="$1"
  local dest="$2"
  shift 2

  local template_dir
  template_dir="$(mage_templates_dir)/${template}"

  if [[ ! -d "$template_dir" ]]; then
    mage_error "Could not get the '${template}' template from ${MAGE_TEMPLATES_ARCHIVE}"
    return 1
  fi

  mkdir -p "$dest"
  cp -R "${template_dir}/." "$dest"

  local file
  local content
  local pair

  while IFS= read -r -d '' file; do
    content="$(cat "$file")"

    for pair in "$@"; do
      content="${content//\{\{${pair%%=*}\}\}/${pair#*=}}"
    done

    printf '%s\n' "$content" > "$file"
  done < <(find "$dest" -type f -print0)
}
