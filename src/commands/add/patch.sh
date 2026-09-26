MAGE_ADD_HANDLERS+=("patch|Add a patch: [PKG] to create one from your changes, [PKG] [NAME] [SOURCE], or a repository url")

MAGE_PATCHES_FILE="patches.json"

# Add patches, depending on the input:
# - a GitHub or GitLab repository url adds all of its patches
# - a package with a name and source adds that patch, the source is the last argument
# - a package alone creates a patch from your changes in its vendor folder
function mage_add_patch() {
  mage_require_jq "Adding a patch"
  mage_patch_check_tool || exit 1

  local input="$1"

  if [[ -z "$input" ]]; then
    input="$(mage_ask "Package to patch (vendor/name), or a patch repository url")"
  fi

  if [[ "$input" =~ ^https://(github|gitlab)\.com/ ]]; then
    mage_add_patch_repository "$input" || exit 1
  elif [[ $# -ge 2 ]]; then
    mage_add_patch_entry "$@" || exit 1
  elif [[ "$input" == */* ]]; then
    mage_add_patch_create "$input" || exit 1
  else
    mage_error "Give a package as vendor/name, or a GitHub or GitLab repository url"
    exit 1
  fi

  mage_patch_apply
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
  mage_patch_merge "$temp_dir"
  local status=$?

  rm -rf "$temp_dir"
  return $status
}

# Add an existing patch file or url, the name may be several words as the source is last
function mage_add_patch_entry() {
  local package="$1"
  local name="${*:2:$#-2}"
  local source="${!#}"

  if [[ -z "$name" ]]; then
    name="$(mage_ask "Patch name")"
  fi

  if [[ -z "$name" ]]; then
    mage_error "The patch name is required"
    return 1
  fi

  if [[ "$source" != https://* ]] && [[ "$source" != *.patch ]]; then
    source="${source%.*}.patch"
  fi

  mage_patch_register "$package" "$name" "$source"
}

# Track the vendor folder of the package with a temporary git repository,
# let you make your changes, and save them as a patch in patches/<package>
function mage_add_patch_create() {
  local package="$1"
  local package_dir="vendor/${package}"

  if [[ ! -d "$package_dir" ]]; then
    mage_error "${package_dir} not found, is ${package} installed?"
    return 1
  fi

  # A git repository or a symlinked path repository package is managed by you,
  # so change it directly instead of patching it
  if [[ -e "${package_dir}/.git" ]]; then
    mage_error "${package_dir} is a git repository, change it there instead of patching it"
    return 1
  fi

  if [[ -L "$package_dir" ]]; then
    mage_error "${package_dir} links to a local package, change it there instead of patching it"
    return 1
  fi

  # The baseline commit is what the changes are compared to, without it the
  # diff would hold every file of the package. Hooks, signing and the git
  # user of your machine stay out of it, the repository is removed after.
  git -C "$package_dir" init --quiet &&
    git -C "$package_dir" add -A &&
    git -C "$package_dir" -c user.name=mage -c user.email=mage@localhost -c commit.gpgsign=false \
      commit --quiet --no-verify --allow-empty -m "Baseline" || return 1

  mage_patch_wait_for_changes "$package_dir"

  local slug="${package//\//-}"
  local name="Local: ${slug}"
  local patch_file="patches/${package}/LOCAL-${slug}.patch"
  local count=2

  while [[ -e "$patch_file" ]]; do
    name="Local: ${slug} ${count}"
    patch_file="patches/${package}/LOCAL-${slug}-${count}.patch"
    count=$((count + 1))
  done

  mkdir -p "patches/${package}"
  git -C "$package_dir" add -A
  git -C "$package_dir" diff --cached > "$patch_file"
  rm -rf "${package_dir}/.git"

  if [[ ! -s "$patch_file" ]]; then
    rm -f "$patch_file"
    mage_error "No changes found in ${package_dir}, no patch created"
    return 1
  fi

  mage_check 0 "Created ${patch_file}"
  mage_patch_register "$package" "$name" "$patch_file"
}

function mage_patch_wait_for_changes() {
  read -r -s -n 1 -p "Make your changes in $1, then press any key to continue"
  echo "" >&2
}

# The functions below hold what depends on the patch tool, now cweagans/composer-patches

function mage_patch_check_tool() {
  if [[ ! -d vendor/cweagans/composer-patches ]]; then
    mage_error "Patches require cweagans/composer-patches, add it with 'mage add cweagans/composer-patches'"
    return 1
  fi
}

# Add a patch to the patches file, which is created when missing
function mage_patch_register() {
  mage_patches_file_init
  jq --arg package "$1" --arg name "$2" --arg source "$3" \
    '.patches[$package][$name] = $source' "$MAGE_PATCHES_FILE" > "${MAGE_PATCHES_FILE}.tmp" &&
    mv "${MAGE_PATCHES_FILE}.tmp" "$MAGE_PATCHES_FILE" || return 1

  mage_check 0 "Added '$2' for $1 to ${MAGE_PATCHES_FILE}"
}

# Merge the patches file of a patch repository into the project, and copy its patches.
# The patches come from its patches folder, or the whole repository when it has none.
function mage_patch_merge() {
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

function mage_patch_apply() {
  $COMPOSER_CLI patches-relock && $COMPOSER_CLI patches-repatch
}

function mage_patches_file_init() {
  if [[ ! -f "$MAGE_PATCHES_FILE" ]]; then
    echo '{ "patches": {} }' > "$MAGE_PATCHES_FILE"
  fi
}
