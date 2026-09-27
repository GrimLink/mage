MAGE_ADD_HANDLERS+=("admin|Create an admin user, the MAGE_ADMIN_* settings are the defaults, -y uses them without asking")

function mage_add_admin() {
  mage_git_defaults

  local email="$MAGE_ADMIN_EMAIL"
  local firstname="$MAGE_ADMIN_FIRSTNAME"
  local lastname="$MAGE_ADMIN_LASTNAME"
  local user="$MAGE_ADMIN_USER"
  local pass="$MAGE_ADMIN_PASS"

  case "$1" in
    "") ;;
    -y | --yes) ;;
    *)
      mage_error "Unknown option '$1'"
      exit 1
      ;;
  esac

  if [[ -z "$1" ]]; then
    email="$(mage_ask "Email" "$email")"
    firstname="$(mage_ask "First name" "$firstname")"
    lastname="$(mage_ask "Last name" "$lastname")"
    user="$(mage_ask "Username" "$user")"

    local answer=""
    read -r -s -p "Password (empty for the one in the config): " answer
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
