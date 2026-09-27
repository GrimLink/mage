load helper

function setup() {
  load_mage
  mkdir -p "${BATS_TEST_TMPDIR}/shop"
  cd "${BATS_TEST_TMPDIR}/shop"
  mkdir -p app/etc pub var/backups
  touch app/etc/env.php
  echo "dump" | gzip > var/backups/shop-20260101-120000.sql.gz
  MAGERUN_CLI="echo magerun"
  MAGENTO_CLI="echo magento"
  MAGE_STORE_CONFIG=("general/country/default NL")
  function mage_env_php() { return 1; }
  # The php args go to stderr, as the output is read for the store views
  function mage_php() {
    echo "php ${*:2}" >&2
    printf 'STORE:store.test default\nSTORE:b2b.store.test b2b\nSTORE:store.test nl\n'
  }
}

@test "restores the latest backup, and sets it up for this device" {
  touch -t 202601020000 var/backups/shop-20260101-120000.sql.gz
  echo "old" | gzip > var/backups/shop-20251231-120000.sql.gz
  touch -t 202601010000 var/backups/shop-20251231-120000.sql.gz

  run mage_cmd_restore --no-media <<< "shop"
  [ "$status" -eq 0 ]
  [[ "$output" == *"magerun db:import --no-interaction --drop --compression=gzip ${PWD}/var/backups/shop-20260101-120000.sql.gz"* ]]
  [[ "$output" == *"php https://shop.test/ test shop localhost 9200"* ]]
  [[ "$output" == *"magento deploy:mode:set developer"* ]]
  [[ "$output" == *"magento indexer:reindex"* ]]
  [[ "$output" == *"shop is restored!"* ]]
  [[ "$output" == *"Store: https://store.test/"* ]]
}

@test "makes the domain of each store view reachable, once per domain" {
  function env_local_add_store() { echo "add store $1 $2"; }

  run mage_cmd_restore --no-media <<< "shop"
  [[ "$output" == *"add store store.test default"* ]]
  [[ "$output" == *"add store b2b.store.test b2b"* ]]
  [[ "$output" != *"add store store.test nl"* ]]
}

@test "errors when the config can not be pointed to this device" {
  function mage_php() { return 1; }

  run mage_cmd_restore --no-media <<< "shop"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Could not point the config to this device"* ]]
}

@test "restores the given file" {
  echo "dump" | gzip > "${BATS_TEST_TMPDIR}/other.sql.gz"

  run mage_cmd_restore --no-media "${BATS_TEST_TMPDIR}/other.sql.gz" <<< "shop"
  [[ "$output" == *"--compression=gzip ${BATS_TEST_TMPDIR}/other.sql.gz"* ]]
}

@test "aborts without the project name" {
  run mage_cmd_restore --no-media <<< "nope"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Aborting restore"* ]]
  [[ "$output" != *"db:import"* ]]
}

@test "needs Magento installed" {
  rm app/etc/env.php

  run mage_cmd_restore <<< "shop"
  [ "$status" -eq 1 ]
  [[ "$output" == *"run 'mage setup' first"* ]]
}

@test "errors without a backup" {
  rm var/backups/*

  run mage_cmd_restore <<< "shop"
  [ "$status" -eq 1 ]
  [[ "$output" == *"No backup found in var/backups"* ]]
}

@test "unpacks the media backup next to the dump" {
  mkdir -p media/wysiwyg
  touch media/wysiwyg/logo.png
  tar -czf var/backups/shop-20260101-120000-media.tar.gz media
  rm -r media

  run mage_cmd_restore --media <<< "shop"
  [ "$status" -eq 0 ]
  [ -e pub/media/wysiwyg/logo.png ]
}

@test "asks for the media, yes by default" {
  mkdir media
  tar -czf var/backups/shop-20260101-120000-media.tar.gz media

  run mage_cmd_restore <<< $'\nshop'
  [ "$status" -eq 0 ]
  [[ "$output" == *"Media from"* ]]
}

@test "errors when the media backup is missing" {
  run mage_cmd_restore --media <<< "shop"
  [ "$status" -eq 1 ]
  [[ "$output" == *"-media.tar.gz not found"* ]]
}

@test "upgrades when the modules differ from the backup" {
  function magento() {
    [[ "$1" == "setup:db:status" ]] && return 2
    echo "magento $*"
  }
  MAGENTO_CLI="magento"

  run mage_cmd_restore --no-media <<< "shop"
  [[ "$output" == *"magento setup:upgrade"* ]]
}

@test "falls back to mysql without magerun" {
  MAGERUN_CLI=""
  MAGERUN_CHECKED=1
  MYSQL_CLI="echo mysql"

  run mage_cmd_restore --no-media <<< "shop"
  [[ "$output" == *"mysql -hlocalhost -uroot -e DROP DATABASE IF EXISTS \`shop\`; CREATE DATABASE \`shop\`;"* ]]
}

@test "streams the dump into the warden db container" {
  function warden() { echo "warden $*"; }
  mage_env_use warden
  MAGENTO_CLI="echo magento"

  run mage_cmd_restore --no-media <<< "shop"
  [[ "$output" == *"warden env exec -T db mysql -umagento -pmagento -e DROP DATABASE IF EXISTS \`magento\`"* ]]
  [[ "$output" == *"php https://shop.test/ test magento opensearch 9200"* ]]
}

@test "imports with ddev" {
  function ddev() { echo "ddev $*"; }
  mage_env_use ddev
  MAGENTO_CLI="echo magento"

  run mage_cmd_restore --no-media <<< "shop"
  [[ "$output" == *"ddev import-db --file=${PWD}/var/backups/shop-20260101-120000.sql.gz"* ]]
  [[ "$output" == *"php https://shop.ddev.site/ ddev.site"* ]]
}
