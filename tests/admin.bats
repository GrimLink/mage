load helper

function setup() {
  load_mage
  MAGENTO_CLI="echo magento"
  MAGERUN_CLI="echo magerun"
  MAGE_ADMIN_EMAIL="me@example.com"
  MAGE_ADMIN_FIRSTNAME="Me"
  MAGE_ADMIN_LASTNAME="admin"
  MAGE_ADMIN_USER="me"
  MAGE_ADMIN_PASS="secret123"
}

@test "creates an admin with the config defaults using -y" {
  run mage_cmd_add admin -y
  [ "$output" = "magento admin:user:create --admin-user=me --admin-password=secret123 --admin-email=me@example.com --admin-firstname=Me --admin-lastname=admin" ]
}

@test "asks for the admin, where empty answers use the defaults" {
  run mage_cmd_add admin <<< $'other@example.com\n\n\nother\n'
  [[ "$output" == *"--admin-user=other --admin-password=secret123 --admin-email=other@example.com --admin-firstname=Me"* ]]
}

@test "rejects unknown options" {
  run mage_cmd_add admin --nope
  [ "$status" -eq 1 ]
}

@test "creates a customer through magerun" {
  run mage_cmd_add customer me@example.com secret123 Me Customer base
  [ "$output" = "magerun customer:create me@example.com secret123 Me Customer base" ]
}

@test "keeps the placeholders without a git user, and configured values" {
  export HOME="$BATS_TEST_TMPDIR"
  export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
  MAGE_ADMIN_USER="configured"
  MAGE_ADMIN_FIRSTNAME="acme"
  MAGE_ADMIN_EMAIL="info@example.com"

  mage_system_user

  [ "$MAGE_ADMIN_USER" = "configured" ]
  [ "$MAGE_ADMIN_FIRSTNAME" = "acme" ]
  [ "$MAGE_ADMIN_EMAIL" = "info@example.com" ]
}

@test "replaces the placeholders with the git user" {
  export HOME="$BATS_TEST_TMPDIR"
  export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
  printf '[user]\n\tname = Sean Grim\n\temail = sean@example.org\n' > "$HOME/.gitconfig"
  MAGE_ADMIN_USER="acme"
  MAGE_ADMIN_FIRSTNAME="acme"
  MAGE_ADMIN_EMAIL="info@example.com"

  mage_system_user

  [ "$MAGE_ADMIN_FIRSTNAME" = "Sean" ]
  [ "$MAGE_ADMIN_USER" = "sean" ]
  [ "$MAGE_ADMIN_EMAIL" = "sean@example.org" ]
}
