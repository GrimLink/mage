MAGE_ADD_HANDLERS+=("theme|Create a child theme, options: [Vendor/Name] [--parent=THEME] [--admin]")

MAGE_HYVA_THEME_DIR="vendor/hyva-themes/magento2-default-theme"

# Create a child theme in app/design, or as a composer package in package-source.
# Anything not given as an option is asked.
function mage_add_theme() {
  local name=""
  local parent=""
  local area="frontend"
  local arg

  for arg in "$@"; do
    case "$arg" in
      --parent=*) parent="${arg#*=}" ;;
      --admin) area="adminhtml" ;;
      -*)
        mage_error "Unknown option '${arg}'"
        exit 1
        ;;
      *) name="$arg" ;;
    esac
  done

  mage_ask_vendor_name "Theme" "$name" || exit 1

  if [[ -z "$parent" ]]; then
    parent="$(mage_ask "Parent theme" "$(mage_theme_default_parent "$area")")"
  fi

  local theme_path="${MAGE_NEW_VENDOR}/${MAGE_NEW_NAME_PKG}"
  local package="${MAGE_NEW_VENDOR_PKG}/magento2-theme-${MAGE_NEW_NAME_PKG}"
  local dest="app/design/${area}/${theme_path}"
  local in_package_source=0

  if mage_confirm "Create it in ${MAGE_PACKAGE_SOURCE} as a composer package?"; then
    in_package_source=1
    dest="${MAGE_PACKAGE_SOURCE}/${package}"
  fi

  if [[ -e "$dest" ]]; then
    mage_error "${dest} already exists, aborting.."
    exit 1
  fi

  mage_git_defaults
  mage_copy_template "theme" "$dest" \
    "AREA=${area}" \
    "PATH=${theme_path}" \
    "VENDOR=${MAGE_NEW_VENDOR}" \
    "NAME=${MAGE_NEW_NAME}" \
    "VENDOR_PKG=${MAGE_NEW_VENDOR_PKG}" \
    "NAME_PKG=${MAGE_NEW_NAME_PKG}" \
    "EMAIL=${GIT_EMAIL}" \
    "PARENT=${parent}" || exit 1

  if [[ "$parent" == Hyva/* ]]; then
    mage_theme_copy_tailwind "$dest"
  fi

  mage_check 0 "Created theme ${area}/${theme_path} in ${dest}"

  if [[ $in_package_source == 1 ]]; then
    mage_add_require_local "$package"
  fi

  mage_notice "Run 'mage setup:upgrade' to register the theme"
}

# Echo the parent theme to suggest, Hyva when it is installed
function mage_theme_default_parent() {
  if [[ "$1" == "adminhtml" ]]; then
    echo "Magento/backend"
  elif [[ -d "$MAGE_HYVA_THEME_DIR" ]]; then
    echo "Hyva/default"
  else
    echo "Magento/luma"
  fi
}

# A Hyva child theme builds its own styles, from a copy of the tailwind folder of the default theme
function mage_theme_copy_tailwind() {
  local source="${MAGE_HYVA_THEME_DIR}/web/tailwind"

  if [[ ! -d "$source" ]]; then
    mage_warn "${source} not found, copy the tailwind folder of the parent theme yourself"
    return 1
  fi

  mkdir -p "$1/web/tailwind"
  rsync -a --exclude node_modules "${source}/" "$1/web/tailwind/"
  mage_check $? "Copied the Hyva tailwind folder"
}
