MAGE_ADD_HANDLERS+=("hyva|Add the Hyva Theme with a license, or with --dev from the Hyva GitLab")

MAGE_HYVA_HOST="hyva-themes.repo.packagist.com"

# Install Hyva from its composer fragment, then make it the active theme where possible.
# The fragment holds the composer part, so updating the packages needs no rebuild.
function mage_add_hyva() {
  local fragment="composer-hyva.json"
  local options=()
  local arg

  for arg in "$@"; do
    case "$arg" in
      --dev) fragment="composer-hyva-dev.json" ;;
      --keep-wildcard) options+=("$arg") ;;
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

  mage_add_json "$file" ${options[@]+"${options[@]}"} || exit 1

  if [[ "$fragment" == "composer-hyva.json" ]]; then
    mage_hyva_save_auth "$(jq -r --arg host "$MAGE_HYVA_HOST" '.auth."http-basic"[$host].password // empty' <<< "$MAGE_ADD_JSON_APPLIED")"
  fi

  $MAGENTO_CLI setup:upgrade || exit 1

  # The Hyva default theme does not support the Magento captcha
  $MAGENTO_CLI config:set customer/captcha/enable 0 &> /dev/null

  mage_set_theme Hyva/default

  mage_info "Done! For more information, see https://docs.hyva.io/hyva-themes/getting-started/"
}

# Cache the Hyva license key in var/composer_home/auth.json, as hyva:sampledata:deploy runs
# composer with that composer home and would ask for it. Without a key, as the global composer
# auth already had one and it was not asked, MAGE_VAR_HYVA_LICENSE_KEY is used when set.
function mage_hyva_save_auth() {
  local file="var/composer_home/auth.json"
  local key="${1:-${MAGE_VAR_HYVA_LICENSE_KEY:-}}"

  if [[ -z "$key" ]]; then
    return 0
  fi

  local auth="{}"
  if [[ -f "$file" ]]; then
    auth="$(cat "$file")"
  fi

  if ! auth="$(jq --indent 4 --arg host "$MAGE_HYVA_HOST" --arg key "$key" '."http-basic"[$host] = {username: "token", password: $key}' <<< "$auth" 2> /dev/null)"; then
    mage_warn "Could not save the Hyva license, ${file} is not valid json"
    return 0
  fi

  mkdir -p "${file%/*}"
  (umask 077 && printf '%s\n' "$auth" > "$file")
  mage_check 0 "Saved the Hyva license in ${file}, for the sample data"
}
