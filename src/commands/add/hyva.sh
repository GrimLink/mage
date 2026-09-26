MAGE_ADD_HANDLERS+=("hyva|Add the Hyva Theme with a license, or with --dev from the Hyva GitLab")

# Install Hyva from its composer fragment.
# The fragment holds the composer part, so updating the packages needs no rebuild.
function mage_add_hyva() {
  local fragment="composer-hyva.json"
  local arg

  for arg in "$@"; do
    case "$arg" in
      --dev) fragment="composer-hyva-dev.json" ;;
      *)
        mage_error "Unknown option '${arg}'"
        exit 1
        ;;
    esac
  done

  local file
  file="$(mage_template_file "$fragment")"

  if [[ -z "$file" ]]; then
    mage_error "Could not get the '${fragment}' template from ${MAGE_TEMPLATES_ARCHIVE}"
    exit 1
  fi

  mage_add_json "$file" || exit 1

  $MAGENTO_CLI setup:upgrade || exit 1

  # The Hyva default theme does not support the Magento captcha
  $MAGENTO_CLI config:set customer/captcha/enable 0 &> /dev/null

  mage_notice "Select the Hyva/default theme in the admin, under Content, Design, Configuration"

  mage_info "Done! For more information, see https://docs.hyva.io/hyva-themes/getting-started/"
}

