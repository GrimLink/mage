load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
}

@test "setup writes the valet env and the driver that keeps assets fresh" {
  env_valet_setup_finish shop > /dev/null

  grep -q "'shop' => \[" .valet-env.php
  grep -q "Cache-Control: no-cache" LocalValetDriver.php
  grep -q "class LocalValetDriver extends Magento2ValetDriver" LocalValetDriver.php
}

@test "keeps an existing driver" {
  echo "<?php // mine" > LocalValetDriver.php

  run env_valet_setup_finish shop
  [ "$(cat LocalValetDriver.php)" = "<?php // mine" ]
  [[ "$output" == *"already present"* ]]
}
