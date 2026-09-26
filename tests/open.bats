load helper

function fake_php() {
  echo "Deprecated: some notice"
  case "${@: -1}" in
    admin) echo "URL:https://shop.test/shop_admin/" ;;
    luma|"") echo "URL:https://luma.shop.test/" ;;
    *) echo "CODES:default, luma" ;;
  esac
}

function setup() {
  load_mage
  PHP_CLI="fake_php"
  OPEN_CLI="echo open"
}

@test "opens the url Magento gives" {
  run mage_cmd_open luma
  [ "$status" -eq 0 ]
  [[ "$output" == *"Opening https://luma.shop.test/"* ]]
  [[ "$output" != *"Deprecated"* ]]
}

@test "opens the admin" {
  run mage_cmd_open admin
  [[ "$output" == *"Opening https://shop.test/shop_admin/"* ]]
}

@test "lists the store codes for an unknown store view" {
  run mage_cmd_open nope
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown store view 'nope', use admin or one of: default, luma"* ]]
}

@test "only prints the url without an open command" {
  OPEN_CLI="no-such-open-command"

  run mage_cmd_open luma
  [ "$status" -eq 0 ]
  [ "$output" = "Opening https://luma.shop.test/" ]
}

@test "opens the mail catcher of the environment" {
  MAGE_MAIL_URL="http://localhost:8025"
  run mage_cmd_open mail
  [ "$output" = "Opening http://localhost:8025" ]

  mage_env_use warden
  run mage_cmd_open mail
  [ "$output" = "Opening https://webmail.warden.test/" ]

  function ddev() { echo "ddev $*"; }
  mage_env_use ddev
  run mage_cmd_open mail
  [ "$output" = "ddev launch -m" ]
}
