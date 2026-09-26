function mage_add_package() {
  local REQUIRE_ARGS=("${@}")

  if [[ "$1" == *".git" ]]; then
    local package_name=$(mage_clone_package "$1" "package-source")

    if [[ -z "$package_name" ]]; then
      REQUIRE_ARGS=()
    else
      echo "Requiring package $package_name..."
      REQUIRE_ARGS=("${package_name}:@dev" "${@:2}")
    fi
  fi

  if [[ ${#REQUIRE_ARGS[@]} -gt 0 ]]; then
    $COMPOSER_CLI require "${REQUIRE_ARGS[@]}"
  fi
}

# Clone a git repository into a folder as vendor/name and echo the package name.
# Progress and errors go to stderr, as the package name is the return value.
function mage_clone_package() {
  local git_url="$1"
  local base_dir="$2"
  local temp_dir="${base_dir}/tmp_clone_$$"

  echo "Cloning ${git_url}..." >&2
  mkdir -p "$base_dir"
  git clone "$git_url" "$temp_dir" >&2

  local package_name=""
  if [[ -f "$temp_dir/composer.json" ]]; then
    package_name=$(get_composer_pkg_name_from_file "$temp_dir/composer.json")
  fi

  if [[ -z "$package_name" ]]; then
    if [[ ! -f "$temp_dir/composer.json" ]]; then
      echo "Error: No composer.json found in the repository." >&2
    else
      echo "Error: Could not parse package name from composer.json." >&2
    fi
    rm -rf "$temp_dir"
    return 1
  fi

  local target_dir="${base_dir}/${package_name}"

  if [[ -d "$target_dir" ]]; then
    echo "Warning: Directory ${target_dir} already exists." >&2
    rm -rf "$temp_dir"
    return 1
  fi

  mkdir -p "$(dirname "$target_dir")"
  mv "$temp_dir" "$target_dir"

  echo "$package_name"
}

# Echo the folder with the global packages, created when missing.
# It holds git clones, the same way package-source does for a single project,
# so every project can require the same local copy.
function mage_packages_dir() {
  local packages_dir="$(mage_config_dir)/composer"
  mkdir -p "$packages_dir"
  echo "$packages_dir"
}

# Echo vendor/name based on a git url
function mage_git_url_path() {
  echo "${1%.git}" | awk -F/ '{ if (NF > 1) print $(NF-1)"/"$NF; else print $NF }' | sed 's/.*://'
}

function is_using_global_packages() {
  [ -f "composer.json" ] && grep -q '"mage-packages"' composer.json
}

# Register the global packages as a composer path repository,
# so the project resolves them before the packages of a private repository
function mage_use_global_packages() {
  local packages_dir="$(mage_packages_dir)"

  if [[ $WARDEN == 1 ]]; then
    echo -e "${YELLOW}Note: ${packages_dir} is outside the Warden container, mount it to use the global packages${RESET}"
  fi

  if ! is_using_global_packages; then
    $COMPOSER_CLI config repositories.mage-packages path "${packages_dir}/*/*"
  fi

  mage_ask_update_global_packages
}

# Clone a git repository into the global packages, when it is not there yet.
# The folder follows the git url, as the package name is only known after cloning.
function mage_add_global_package() {
  local git_url="$1"
  local path="${2:-$(mage_git_url_path "$git_url")}"
  local packages_dir="$(mage_packages_dir)"
  local target_dir="${packages_dir}/${path}"

  if [[ -d "$target_dir" ]]; then
    echo -e " [${GREEN}✓${RESET}] ${path}"
    return
  fi

  mkdir -p "$(dirname "$target_dir")"

  if ! git clone --quiet "$git_url" "$target_dir"; then
    echo -e " [${RED}✗${RESET}] ${path}"
    return 1
  fi

  touch "${packages_dir}/.updated"
  echo -e " [${GREEN}✓${RESET}] ${path}"
}

# Clone a git repository into the global packages and require it in the project
function mage_add_dev_package() {
  local git_url="$1"

  if [[ -z "$git_url" ]]; then
    echo "The git url of the package is required, Example: mage add dev git@gitlab.hyva.io:hyva-themes/magento2-theme-module.git"
    return 1
  fi

  local path="$(mage_git_url_path "$git_url")"

  mage_add_global_package "$git_url" "$path" || return 1
  mage_use_global_packages

  local package_name=$(get_composer_pkg_name_from_file "$(mage_packages_dir)/${path}/composer.json")

  if [[ -z "$package_name" ]]; then
    echo "Could not parse the package name from ${path}/composer.json"
    return 1
  fi

  $COMPOSER_CLI require "${package_name}:@dev"
}

# Update every clone in the global packages
function mage_update_global_packages() {
  local packages_dir="$(mage_packages_dir)"
  local repo=""

  for repo in "${packages_dir}"/*/*; do
    if [[ ! -d "${repo}/.git" ]]; then
      continue
    fi

    if git -C "$repo" pull --quiet &> /dev/null; then
      echo -e " [${GREEN}✓${RESET}] ${repo#${packages_dir}/}"
    else
      echo -e " [${RED}✗${RESET}] ${repo#${packages_dir}/}"
    fi
  done

  touch "${packages_dir}/.updated"
}

# Ask to update the global packages, when they were last updated over 30 days ago
function mage_ask_update_global_packages() {
  local packages_dir="$(mage_packages_dir)"
  local marker="${packages_dir}/.updated"
  local repo=""
  local has_packages=0

  for repo in "${packages_dir}"/*/*; do
    if [[ -d "$repo" ]]; then
      has_packages=1
      break
    fi
  done

  if [[ $has_packages == 0 ]]; then
    return
  fi

  if [[ -f "$marker" ]] && [[ -z "$(find "$marker" -mtime +30)" ]]; then
    return
  fi

  if mage_confirm "The global packages were not updated for a while, update them now?" "y"; then
    mage_update_global_packages
  fi
}
