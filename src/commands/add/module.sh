MAGE_ADD_HANDLERS+=("module|Create a module, options: [Vendor/Name] [--hyva|--no-hyva]")

# Create a module in app/code, or as a composer package in package-source.
# A Hyva module also registers its tailwind sources with the Hyva config.
# Anything not given as an option is asked.
function mage_add_module() {
  local name=""
  local hyva=""
  local arg

  for arg in "$@"; do
    case "$arg" in
      --hyva) hyva=1 ;;
      --no-hyva) hyva=0 ;;
      -*)
        mage_error "Unknown option '${arg}'"
        exit 1
        ;;
      *) name="$arg" ;;
    esac
  done

  mage_ask_vendor_name "Module" "$name" || exit 1

  # The names end up in the PHP namespace
  if [[ ! "$MAGE_NEW_VENDOR" =~ ^[A-Za-z][A-Za-z0-9]*$ ]] || [[ ! "$MAGE_NEW_NAME" =~ ^[A-Za-z][A-Za-z0-9]*$ ]]; then
    mage_error "The vendor and module name can only contain letters and numbers, such as Vendor/MyModule"
    exit 1
  fi

  if [[ -z "$hyva" ]]; then
    local hyva_default="n"
    if mage_is_hyva_installed; then
      hyva_default="y"
    fi

    hyva=0
    if mage_confirm "Is this a Hyva module?" "$hyva_default"; then
      hyva=1
    fi
  fi

  local package="${MAGE_NEW_VENDOR_PKG}/magento2-${MAGE_NEW_NAME_PKG}"
  local dest="app/code/${MAGE_NEW_VENDOR}/${MAGE_NEW_NAME}"
  local in_package_source=0

  if mage_confirm "Create it in ${MAGE_PACKAGE_SOURCE} as a composer package?"; then
    in_package_source=1
    dest="${MAGE_PACKAGE_SOURCE}/${package}"
  fi

  if [[ -e "$dest" ]]; then
    mage_error "${dest} already exists, aborting.."
    exit 1
  fi

  local sequence="Magento_Theme"
  if [[ $hyva == 1 ]]; then
    sequence="Hyva_Theme"
  fi

  local template_vars=(
    "VENDOR=${MAGE_NEW_VENDOR}"
    "MODULE=${MAGE_NEW_NAME}"
    "VENDOR_PKG=${MAGE_NEW_VENDOR_PKG}"
    "MODULE_PKG=${MAGE_NEW_NAME_PKG}"
    "EMAIL=security@example.com"
    "SEQUENCE=${sequence}"
  )

  mage_copy_template "module" "$dest" "${template_vars[@]}" || exit 1

  if [[ $hyva == 1 ]]; then
    mage_copy_template "module-hyva" "$dest" "${template_vars[@]}" || exit 1
  fi

  mage_check 0 "Created module ${MAGE_NEW_VENDOR}_${MAGE_NEW_NAME} in ${dest}"

  if [[ $in_package_source == 1 ]]; then
    mage_add_require_local "$package"
  fi

  mage_notice "Run 'mage setup:upgrade' to enable the module"
}
