MAGE_ADD_HANDLERS+=("admin|Create an admin user, the MAGE_ADMIN_* settings are the defaults, -y uses them without asking")

function mage_add_admin() {
  mage_system_user

  local email="$MAGE_ADMIN_EMAIL"
  local firstname="$MAGE_ADMIN_FIRSTNAME"
  local lastname="$MAGE_ADMIN_LASTNAME"
  local user="$MAGE_ADMIN_USER"
  local pass="$MAGE_ADMIN_PASS"

  case "$1" in
    "") ;;
    -y | --yes) MAGE_YES=1 ;;
    *)
      mage_error "Unknown option '$1'"
      exit 1
      ;;
  esac

  if [[ $MAGE_YES != 1 ]]; then
    email="$(mage_ask "Email" "$email")" || exit 1
    firstname="$(mage_ask "First name" "$firstname")" || exit 1
    lastname="$(mage_ask "Last name" "$lastname")" || exit 1
    user="$(mage_ask "Username" "$user")" || exit 1

    local answer=""
    read -r -s -p "Password (empty for the one in the config): " answer || mage_no_answer "Password"
    echo "" >&2
    pass="${answer:-$pass}"
  fi

  $MAGENTO_CLI admin:user:create \
    --admin-user="$user" \
    --admin-password="$pass" \
    --admin-email="$email" \
    --admin-firstname="$firstname" \
    --admin-lastname="$lastname"
}
