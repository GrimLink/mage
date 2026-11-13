# Check the code with the Hyvä coding standard, which extends the Magento one.
# Hyvä advises against adding it to the project, as it shares dependencies with
# Magento, so it is a stand-alone install: in the mage config on your machine,
# or with Warden and DDEV in the project, as the container only sees the project.
MAGE_LINT_PACKAGE="hyva-themes/hyva-coding-standard"
MAGE_LINT_STANDARD="HyvaThemes"
MAGE_LINT_PROJECT_DIR="hyva-coding-standard"

# Lint the given paths, never the whole project, as that also holds the vendor folders
# of local packages. --fix runs phpcbf instead, other options go to phpcs, such as -s.
function mage_cmd_lint() {
  local bin="phpcs"
  local options=()
  local paths=()
  local arg
  local path

  for arg in "$@"; do
    case "$arg" in
      --fix) bin="phpcbf" ;;
      -*) options+=("$arg") ;;
      *)
        path="$(mage_resolve_path "$arg")"

        if [[ $LINT_IN_PROJECT == 1 ]] && [[ "$path" == /* ]]; then
          if [[ "$path" != "$MAGE_ROOT"/* ]]; then
            mage_error "The container only sees the project, so '${arg}' cannot be linted"
            exit 1
          fi

          path="${path#"$MAGE_ROOT"/}"
        fi

        paths+=("$path")
        ;;
    esac
  done

  if [[ ${#paths[@]} -eq 0 ]]; then
    mage_error "Give a path to lint, such as 'mage lint app/code/Acme/Module'"
    exit 1
  fi

  if ! mage_lint_installed "$bin"; then
    mage_lint_install || exit 1
  fi

  # -p shows the progress, as phpcs shows nothing else until it is done
  $LINT_PHP_CLI "$(mage_lint_dir)/vendor/bin/${bin}" --standard="$MAGE_LINT_STANDARD" -p "${options[@]}" "${paths[@]}"
}

# Echo the folder of the coding standard
function mage_lint_dir() {
  if [[ $LINT_IN_PROJECT == 1 ]]; then
    echo "$MAGE_LINT_PROJECT_DIR"
  else
    echo "$(mage_config_dir)/hyva-coding-standard"
  fi
}

# Check for the given bin of the coding standard. In a container it checks there,
# as a sync to the host, such as mutagen, can lag behind.
function mage_lint_installed() {
  local file
  file="$(mage_lint_dir)/vendor/bin/$1"

  if [[ $LINT_IN_PROJECT == 1 ]]; then
    $LINT_PHP_CLI -r "exit(is_file('${file}') ? 0 : 1);" &> /dev/null
  else
    [[ -f "$file" ]]
  fi
}

# Install the latest coding standard as a stand-alone composer project.
# It is installed next to the current one first, so a failure keeps that one.
function mage_lint_install() {
  local target
  target="$(mage_lint_dir)"
  local temp_dir="${target}.tmp"

  if ! command -v "${LINT_PHP_CLI%% *}" &> /dev/null || ! command -v "${LINT_COMPOSER_CLI%% *}" &> /dev/null; then
    mage_error "Linting needs php and composer on your machine"
    return 1
  fi

  mage_info "Installing ${MAGE_LINT_PACKAGE} in ${target}"
  $LINT_PURGE_CLI "$temp_dir"

  if ! $LINT_COMPOSER_CLI create-project --no-plugins --no-dev --no-interaction "$MAGE_LINT_PACKAGE" "$temp_dir"; then
    $LINT_PURGE_CLI "$temp_dir"
    mage_error "Could not install ${MAGE_LINT_PACKAGE}"
    return 1
  fi

  $LINT_PURGE_CLI "$target"
  mage_lint_move "$temp_dir" "$target"
}

# Move a folder where lint runs, the container or your machine
function mage_lint_move() {
  if [[ $LINT_IN_PROJECT == 1 ]]; then
    $LINT_PHP_CLI -r "exit(rename('$1', '$2') ? 0 : 1);"
  else
    mv "$1" "$2"
  fi
}
