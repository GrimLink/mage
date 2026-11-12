# Check the code with the Hyvä coding standard, which extends the Magento one.
# Hyvä advises against adding it to the project, as it shares dependencies with
# Magento, so it is installed once in the mage config and runs on your machine.
MAGE_LINT_PACKAGE="hyva-themes/hyva-coding-standard"
MAGE_LINT_STANDARD="HyvaThemes"

# Lint the given paths, never the whole project, as that also holds the vendor folders
# of local packages. --fix runs phpcbf instead, other options go to phpcs, such as -s.
function mage_cmd_lint() {
  local bin="phpcs"
  local options=()
  local paths=()
  local arg

  for arg in "$@"; do
    case "$arg" in
      --fix) bin="phpcbf" ;;
      -*) options+=("$arg") ;;
      *) paths+=("$(mage_resolve_path "$arg")") ;;
    esac
  done

  if [[ ${#paths[@]} -eq 0 ]]; then
    mage_error "Give a path to lint, such as 'mage lint app/code/Acme/Module'"
    exit 1
  fi

  if [[ ! -f "$(mage_lint_dir)/vendor/bin/${bin}" ]]; then
    mage_lint_install || exit 1
  fi

  # -p shows the progress, as phpcs shows nothing else until it is done
  $HOST_PHP_CLI "$(mage_lint_dir)/vendor/bin/${bin}" --standard="$MAGE_LINT_STANDARD" -p "${options[@]}" "${paths[@]}"
}

# Echo the folder of the coding standard
function mage_lint_dir() {
  echo "$(mage_config_dir)/hyva-coding-standard"
}

# Install the latest coding standard as a stand-alone composer project.
# It is installed next to the current one first, so a failure keeps that one.
function mage_lint_install() {
  local target
  target="$(mage_lint_dir)"
  local temp_dir="${target}.tmp"

  if ! command -v "${HOST_PHP_CLI%% *}" &> /dev/null || ! command -v "${HOST_COMPOSER_CLI%% *}" &> /dev/null; then
    mage_error "Linting needs php and composer on your machine, also with Warden or DDEV"
    return 1
  fi

  mage_info "Installing ${MAGE_LINT_PACKAGE} in ${target}"
  rm -rf "$temp_dir"

  if ! $HOST_COMPOSER_CLI create-project --no-plugins --no-dev --no-interaction "$MAGE_LINT_PACKAGE" "$temp_dir"; then
    rm -rf "$temp_dir"
    mage_error "Could not install ${MAGE_LINT_PACKAGE}"
    return 1
  fi

  rm -rf "$target"
  mv "$temp_dir" "$target"
}
