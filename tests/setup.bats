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

@test "disables nothing when the install has none of them" {
  printf "<?php\nreturn ['modules' => [\n'Magento_Catalog' => 1,\n]];\n" > app/etc/config.php

  run mage_setup_disable_modules
  [ -z "$output" ]
}
