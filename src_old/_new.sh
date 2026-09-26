function mage_new_in_folder() {
  if [[ ! -d package-source ]]; then
    mkdir package-source
  fi

  if mage_confirm "Create in package-source as local composer package?"; then
    echo "package-source"
  else
    echo $1
  fi
}

# Ask for the vendor and name of a new theme or module,
# accepting either 'Vendor/Name' or both as separate answers.
# The result is shared through NEW_VENDOR, NEW_NAME, NEW_VENDOR_PKG,
# NEW_NAME_PKG and NEW_PATH, as a function can only echo a single value.
function mage_ask_new_package() {
  local label="$1"
  local name=""
  local vendor=""

  read -e -p "${label} Name: " name
  if [[ -z "$name" ]]; then echo "The 'Name' can not be empty" && exit 1; fi

  if [[ "$name" == */* ]]; then
    vendor="${name%%/*}"
    name="${name#*\/}"
  else
    read -e -p "${label} Vendor: " vendor
    if [[ -z "$vendor" ]]; then echo "The 'Vendor' can not be empty" && exit 1; fi
  fi

  NEW_VENDOR="$(echo "$vendor" | tr -d '[:blank:]')"
  NEW_NAME="$(echo "$name" | tr -d '[:blank:]')"
  NEW_VENDOR_PKG="$(mage_lower_case "$NEW_VENDOR")"
  NEW_NAME_PKG="$(mage_kebab_case "$NEW_NAME")"
  NEW_PATH="${NEW_VENDOR}/${NEW_NAME_PKG}"
}

function mage_new_theme() {
  local application="frontend"
  local default_parrent_theme="Hyva/default"

  if mage_confirm "Is this a admin theme?"; then
    application="adminhtml"
  fi

  local dest_path="$(mage_new_in_folder "app/design/${application}")"

  mage_ask_new_package "Theme"

  read -e -p "Parrent Theme ($default_parrent_theme): " parrent_theme
  if [[ -z "$parrent_theme" ]]; then parrent_theme=$default_parrent_theme; fi

  local dest_path="${dest_path}/${NEW_PATH}"

  mage_copy_template "theme" "$dest_path" \
    "AREA=${application}" \
    "PATH=${NEW_PATH}" \
    "VENDOR=${NEW_VENDOR}" \
    "NAME=${NEW_NAME}" \
    "VENDOR_PKG=${NEW_VENDOR_PKG}" \
    "NAME_PKG=${NEW_NAME_PKG}" \
    "EMAIL=${GITEMAIL:-security@example.com}" \
    "PARENT=${parrent_theme}" || return 1

  if [[ $parrent_theme == Hyva/* ]]; then
    mkdir -p "${dest_path}/web/tailwind"
    mage_make_file "${dest_path}/web/tailwind" rsync vendor/hyva-themes/magento2-default-theme/web/tailwind
  fi

  echo "Created theme ${application}/${NEW_PATH} in ${dest_path}"
}

function mage_new_module() {
  local dest_path="$(mage_new_in_folder "app/code")"

  mage_ask_new_package "Module"

  local hyva_default="n"
  if is_hyva_installed; then hyva_default="y"; fi

  local use_hyva=0
  local sequence="Magento_Theme"
  if mage_confirm "Is this a Hyva module?" "$hyva_default"; then
    use_hyva=1
    sequence="Hyva_Theme"
  fi

  local dest_path="${dest_path}/${NEW_PATH}"
  local template_vars=(
    "VENDOR=${NEW_VENDOR}"
    "MODULE=${NEW_NAME}"
    "VENDOR_PKG=${NEW_VENDOR_PKG}"
    "MODULE_PKG=${NEW_NAME_PKG}"
    "EMAIL=${GITEMAIL:-security@example.com}"
    "SEQUENCE=${sequence}"
  )

  mage_copy_template "module" "$dest_path" "${template_vars[@]}" || return 1

  if [[ $use_hyva == 1 ]]; then
    mage_copy_template "module-hyva" "$dest_path" "${template_vars[@]}" || return 1
  fi

  echo "Created module ${NEW_VENDOR}_${NEW_NAME} in ${dest_path}"
}
