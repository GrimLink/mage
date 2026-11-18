load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  MAGENTO_CLI="echo magento"
  mkdir -p app/etc
}

@test "disables the listed modules the install has" {
  printf "<?php\nreturn ['modules' => [\n'Magento_TwoFactorAuth' => 1,\n'MageOS_ThemeOptimization' => 1,\n'Magento_Catalog' => 1,\n]];\n" > app/etc/config.php

  run mage_setup_disable_modules
  [[ "$output" == *"magento module:disable Magento_TwoFactorAuth MageOS_ThemeOptimization" ]]
}

@test "disables the Mage-OS passkeys along with two factor auth" {
  printf "<?php\nreturn ['modules' => [\n'MageOS_PasskeyAuth' => 1,\n'Magento_TwoFactorAuth' => 1,\n]];\n" > app/etc/config.php

  run mage_setup_disable_modules
  [[ "$output" == *"magento module:disable MageOS_PasskeyAuth Magento_TwoFactorAuth" ]]
}

@test "disables nothing when the install has none of them" {
  printf "<?php\nreturn ['modules' => [\n'Magento_Catalog' => 1,\n]];\n" > app/etc/config.php

  run mage_setup_disable_modules
  [ -z "$output" ]
}

@test "sets the store config, and locks the env config in env.php" {
  MAGE_STORE_CONFIG=("general/country/default NL" "admin/security/password_lifetime")
  MAGE_ENV_CONFIG=("admin/security/session_lifetime 86400")
  function mage_set_config_entry() { echo "entry $1 ${2:-}"; }

  run mage_set_store_config
  [ "${lines[0]}" = "entry general/country/default NL " ]
  [ "${lines[1]}" = "entry admin/security/password_lifetime " ]
  [ "${lines[2]}" = "entry admin/security/session_lifetime 86400 --lock-env" ]
}

@test "passes the lock option and an empty value to config:set" {
  MAGENTO_CLI="record_cli"
  function record_cli() { printf '[%s]' "$@" >> "${BATS_TEST_TMPDIR}/cli"; echo >> "${BATS_TEST_TMPDIR}/cli"; }

  mage_set_config_entry "admin/security/session_lifetime 86400" --lock-env
  mage_set_config_entry "admin/security/password_lifetime"

  run cat "${BATS_TEST_TMPDIR}/cli"
  [ "${lines[0]}" = "[config:set][--lock-env][admin/security/session_lifetime][86400]" ]
  [ "${lines[1]}" = "[config:set][admin/security/password_lifetime][]" ]
}
