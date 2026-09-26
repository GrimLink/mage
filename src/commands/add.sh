# Handlers register as 'name|description', see core/handlers.sh
MAGE_ADD_HANDLERS=()

MAGE_PACKAGE_SOURCE="package-source"

# Add to the project: a handler by name, a composer fragment from a json file,
# a git repository by its ssh url, or anything else passed as is to composer require
function mage_cmd_add() {
  case "$1" in
    "")
      mage_error "Nothing to add, use one of the options below"
      mage_add_help
      exit 1
      ;;
    "help" | "-h" | "--help")
      mage_add_help
      return
      ;;
  esac

  if mage_handler_exists "$1" "${MAGE_ADD_HANDLERS[@]}"; then
    mage_handler_run add "$@"
  elif [[ "$1" == *.json ]]; then
    mage_add_json "$1"
  elif [[ "$1" == *.git ]]; then
    mage_add_git "$@"
  else
    $COMPOSER_CLI require "$@"
  fi
}

function mage_add_help() {
  mage_help_header "Add"
  mage_help_cmd "add [PKG] [ARGS]"            "Run composer require, all arguments are passed as is"
  mage_help_cmd "add [FILE].json"             "Apply a composer fragment: repositories, config, auth and packages"
  mage_help_cmd "add [GIT_URL] [ARGS]"        "Clone a git repository (ssh url ending in .git) into ${MAGE_PACKAGE_SOURCE} and require it"
  mage_handler_help add "${MAGE_ADD_HANDLERS[@]}"
}

# Clone a git repository into the package source folder and require it,
# any further arguments go to composer require
function mage_add_git() {
  local url="$1"
  shift

  local target
  target="$(mage_add_find_clone "$url")"

  if [[ -n "$target" ]]; then
    mage_notice "Using the existing clone in ${target}"
  else
    target="$(mage_add_clone "$url")" || return 1
  fi

  local name
  name="$(mage_composer_name "${target}/composer.json")"

  mage_add_path_repository
  $COMPOSER_CLI require "${name}:$(mage_git_constraint "$target")" "$@"
}

# Echo the clone in the package source folder that has the url as its origin
function mage_add_find_clone() {
  local dir

  for dir in "${MAGE_PACKAGE_SOURCE}"/*/*; do
    if [[ -d "${dir}/.git" ]] && [[ "$(git -C "$dir" remote get-url origin 2> /dev/null)" == "$1" ]]; then
      echo "$dir"
      return 0
    fi
  done

  return 1
}

# Clone into the package source folder as vendor/name, and echo that folder.
# The package name is only known after cloning, so it clones to a temporary folder first.
function mage_add_clone() {
  local url="$1"
  local temp_dir="${MAGE_PACKAGE_SOURCE}/.clone-$$"

  mkdir -p "$MAGE_PACKAGE_SOURCE"
  mage_info "Cloning ${url}..." >&2

  if ! git clone --quiet "$url" "$temp_dir"; then
    rm -rf "$temp_dir"
    mage_error "Could not clone ${url}"
    return 1
  fi

  local name
  name="$(mage_composer_name "${temp_dir}/composer.json")"

  if [[ -z "$name" ]]; then
    rm -rf "$temp_dir"
    mage_error "No composer.json with a package name found in ${url}"
    return 1
  fi

  local target="${MAGE_PACKAGE_SOURCE}/${name}"

  if [[ -e "$target" ]]; then
    rm -rf "$temp_dir"
    mage_error "${target} already exists, but is not a clone of ${url}"
    return 1
  fi

  mkdir -p "$(dirname "$target")"
  mv "$temp_dir" "$target"
  echo "$target"
}

# Echo the require constraint for a clone, 'dev-<branch> as <latest tag>'
# so dependencies on a version still resolve, or '@dev' without any tag
function mage_git_constraint() {
  local dir="$1"
  local branch
  local tag

  branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD 2> /dev/null)"
  tag="$(git -C "$dir" describe --tags --abbrev=0 2> /dev/null)"
  tag="${tag#v}"

  if [[ -z "$tag" ]] || [[ -z "$branch" ]] || [[ "$branch" == "HEAD" ]]; then
    echo "@dev"
    return
  fi

  echo "dev-${branch} as ${tag}"
}

# Require a package created in the package source folder
function mage_add_require_local() {
  mage_add_path_repository
  $COMPOSER_CLI require "${1}:@dev"
}

# Register the package source folder as a composer path repository, once
function mage_add_path_repository() {
  if [[ -f composer.json ]] && grep -q '"local-packages"' composer.json; then
    return
  fi

  mage_notice "Registering ${MAGE_PACKAGE_SOURCE} as a composer path repository"
  $COMPOSER_CLI config repositories.local-packages path "${MAGE_PACKAGE_SOURCE}/*/*"
}
