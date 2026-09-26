MAGE_ADD_HANDLERS+=("patch|Add a patch: [PKG] [NAME] [SOURCE], or all patches of a GitHub or GitLab repository url")

MAGE_PATCHES_FILE="patches.json"

# Add patches through cweagans/composer-patches, and apply them right away.
# A GitHub or GitLab repository url adds all of its patches, otherwise the
# arguments are the package, the patch name and the patch source, the last one.
function mage_add_patch() {
  mage_require_jq "Adding a patch"

  if [[ ! -d vendor/cweagans/composer-patches ]]; then
    mage_error "Patches require cweagans/composer-patches, add it with 'mage add cweagans/composer-patches'"
    exit 1
  fi

  if [[ "$1" =~ ^https://(github|gitlab)\.com/ ]]; then
    mage_add_patch_repository "$1" || exit 1
  else
    mage_add_patch_entry "$@" || exit 1
  fi

  $COMPOSER_CLI patches-relock && $COMPOSER_CLI patches-repatch
}

# Download the main branch of a patch repository, and add its patches
function mage_add_patch_repository() {
  local url="${1%/}"
  local archive_url="${url}/tarball/main"

  if [[ "$url" == https://gitlab.com/* ]]; then
    archive_url="${url}/-/archive/main.tar.gz"
  fi

  local temp_dir
  temp_dir="$(mktemp -d)"

  mage_info "Downloading the patches from ${url}..."

  if ! mage_download_file "$archive_url" "${temp_dir}/patches.tar.gz" ||
    ! tar -xzf "${temp_dir}/patches.tar.gz" -C "$temp_dir" --strip-components=1; then
    rm -rf "$temp_dir"
    mage_error "Could not download the main branch of ${url}"
    return 1
  fi

  rm -f "${temp_dir}/patches.tar.gz"
  mage_add_patch_folder "$temp_dir"
  local status=$?

  rm -rf "$temp_dir"
  return $status
}

# Merge the patches.json of a patch repository into the project, and copy its patches.
# The patches come from its patches folder, or the whole repository when it has none.
function mage_add_patch_folder() {
  local source="$1"

  if [[ -f "${source}/${MAGE_PATCHES_FILE}" ]]; then
    mage_patches_file_init
    jq -s '.[0] * .[1]' "$MAGE_PATCHES_FILE" "${source}/${MAGE_PATCHES_FILE}" > "${MAGE_PATCHES_FILE}.tmp" &&
      mv "${MAGE_PATCHES_FILE}.tmp" "$MAGE_PATCHES_FILE" || return 1
    mage_check 0 "Merged ${MAGE_PATCHES_FILE}"
  fi

  mkdir -p patches

  if [[ -d "${source}/patches" ]]; then
    cp -R "${source}/patches/." patches/
  else
    cp -R "${source}/." patches/
    rm -f "patches/${MAGE_PATCHES_FILE}"
  fi

  mage_check 0 "Copied the patches to patches/"
}

# Add a single patch to patches.json. Anything not given is asked,
# the name may be several words when the source is given last.
function mage_add_patch_entry() {
  local package="$1"
  local name=""
  local source=""

  if [[ $# -ge 3 ]]; then
    name="${*:2:$#-2}"
    source="${!#}"
  elif [[ $# -eq 2 ]]; then
    name="$2"
  fi

  if [[ -z "$package" ]]; then
    package="$(mage_ask "Package to patch, such as magento/module-theme")"
  fi

  if [[ -z "$name" ]]; then
    name="$(mage_ask "Patch name")"
  fi

  if [[ -z "$source" ]]; then
    source="$(mage_ask "Patch source, a file in patches/ or a url")"
  fi

  if [[ -z "$package" ]] || [[ -z "$name" ]] || [[ -z "$source" ]]; then
    mage_error "The package, name and source of the patch are required"
    return 1
  fi

  if [[ "$source" != https://* ]] && [[ "$source" != *.patch ]]; then
    source="${source%.*}.patch"
  fi

  mage_patches_file_init
  jq --arg package "$package" --arg name "$name" --arg source "$source" \
    '.patches[$package][$name] = $source' "$MAGE_PATCHES_FILE" > "${MAGE_PATCHES_FILE}.tmp" &&
    mv "${MAGE_PATCHES_FILE}.tmp" "$MAGE_PATCHES_FILE" || return 1

  mage_check 0 "Added '${name}' for ${package} to ${MAGE_PATCHES_FILE}"
}

function mage_patches_file_init() {
  if [[ ! -f "$MAGE_PATCHES_FILE" ]]; then
    echo '{ "patches": {} }' > "$MAGE_PATCHES_FILE"
  fi
}
