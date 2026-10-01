load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  mkdir -p pub/media/catalog/product/cache pub/media/tmp pub/media/wysiwyg
  touch pub/media/wysiwyg/logo.png pub/media/catalog/product/cache/small.png pub/media/tmp/upload.png
  unset SSH_CONNECTION
  MAGERUN_CLI="echo magerun"
}

@test "dumps the database with magerun, stripping the default groups" {
  run mage_cmd_backup --no-media
  [ "$status" -eq 0 ]

  local file
  file="$(ls var/backups/*.sql.gz)"
  [ "$(gzip -dc "$file")" = "magerun db:dump --stdout --strip=@stripped" ]
  [ ! -e var/backups/*-media.tar.gz ]
}

@test "strips the given groups, or none" {
  mage_cmd_backup --no-media --strip="@development @idx" > /dev/null
  [ "$(gzip -dc var/backups/*.sql.gz)" = "magerun db:dump --stdout --strip=@development @idx" ]

  rm var/backups/*
  mage_cmd_backup --no-media --strip= > /dev/null
  [ "$(gzip -dc var/backups/*.sql.gz)" = "magerun db:dump --stdout" ]
}

@test "archives the media without the folders Magento rebuilds" {
  run mage_cmd_backup --media
  [ "$status" -eq 0 ]

  local list
  list="$(tar -tzf var/backups/*-media.tar.gz)"
  [[ "$list" == *"media/wysiwyg/logo.png"* ]]
  [[ "$list" != *"small.png"* ]]
  [[ "$list" != *"upload.png"* ]]
}

@test "asks for the media without an option" {
  run mage_cmd_backup <<< "y"
  [ -e var/backups/*-media.tar.gz ]
}

@test "uses the backup dir of the config" {
  MAGE_BACKUP_DIR="${BATS_TEST_TMPDIR}/elsewhere"

  run mage_cmd_backup --no-media
  [ -e "${BATS_TEST_TMPDIR}"/elsewhere/*.sql.gz ]
}

@test "shows how to copy it with rsync over ssh" {
  SSH_CONNECTION="10.0.0.1 51234 10.0.0.2 22"
  USER="app"

  run mage_cmd_backup --no-media
  [[ "$output" == *"rsync -P 'app@10.0.0.2:${BATS_TEST_TMPDIR}/var/backups/"* ]]
}

@test "adds the ssh port when it is not 22" {
  SSH_CONNECTION="10.0.0.1 51234 10.0.0.2 2222"
  USER="app"

  run mage_cmd_backup --no-media
  [[ "$output" == *"rsync -P -e 'ssh -p 2222' 'app@10.0.0.2:"* ]]
}

@test "removes the dump when it fails" {
  MAGERUN_CLI="false"

  run mage_cmd_backup --no-media
  [ "$status" -eq 1 ]
  [[ "$output" == *"Could not dump the database"* ]]
  [ -z "$(ls var/backups)" ]
}

@test "falls back to mysqldump without magerun, with the port of the host" {
  MAGERUN_CLI=""
  MAGERUN_CHECKED=1
  MYSQLDUMP_CLI="echo mysqldump"
  MAGE_DB_HOST="localhost:3307"
  function mage_env_php() { return 1; }

  run mage_cmd_backup --no-media
  [ "$status" -eq 0 ]
  [[ "$output" == *"dumping the whole database with mysqldump"* ]]
  [ "$(gzip -dc var/backups/*.sql.gz)" = "mysqldump -hlocalhost -uroot -P3307 --single-transaction --quick --no-tablespaces $(basename "$BATS_TEST_TMPDIR")" ]
}

@test "removes the definers from the mysqldump" {
  MAGERUN_CLI=""
  MAGERUN_CHECKED=1
  MYSQLDUMP_CLI="printf %s\\n"
  function mage_env_php() { return 1; }
  # printf prints its arguments, so feed it a trigger line as the database name
  MAGE_DB_NAME='/*!50017 DEFINER=`magento`@`%`*/ /*!50003 TRIGGER'

  mage_cmd_backup --no-media 2> /dev/null
  [[ "$(gzip -dc var/backups/*.sql.gz)" == *'/*!50017 */ /*!50003 TRIGGER'* ]]
}

@test "errors on an unknown option" {
  run mage_cmd_backup --nope
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown option '--nope'"* ]]
}

@test "uses the magerun of the warden container, without a tty" {
  function warden() { echo "warden $*"; }
  mage_env_use warden

  run mage_cmd_backup --no-media
  [ "$(gzip -dc var/backups/*.sql.gz)" = "warden env exec -T php-fpm n98-magerun db:dump --stdout --strip=@stripped" ]
}

@test "exports the database with ddev" {
  function ddev() { echo "ddev $*"; }
  mage_env_use ddev

  run mage_cmd_backup --no-media
  [[ "$output" == *"the strip groups do not apply"* ]]
  [[ "$output" == *"ddev export-db --gzip --file=${BATS_TEST_TMPDIR}/var/backups/"*".sql.gz"* ]]
}
