load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  SYNC_RSYNC_CLI="echo rsync"
  # The server answers the latest backup
  function ssh() { echo "/data/web/magento2/var/backups/store-20260927-101500.sql.gz"; }
  SSH_CLI="ssh"
}

@test "needs the host" {
  run mage_cmd_sync
  [ "$status" -eq 1 ]
  [[ "$output" == *"Give the ssh host of the server"* ]]
}

@test "pulls the media from the hypernode root by default" {
  run mage_cmd_sync app@store.hypernode.io
  [ "$status" -eq 0 ]
  [[ "$output" == *"rsync -aP --exclude=/media/catalog/product/cache --exclude=/media/captcha --exclude=/media/tmp app@store.hypernode.io:/data/web/magento2/pub/media pub/"* ]]
  [[ "$output" != *".sql.gz"* ]]
}

@test "pulls from the given root, or the one of the config" {
  run mage_cmd_sync store /var/www/store/
  [[ "$output" == *"store:/var/www/store/pub/media pub/"* ]]

  MAGE_SYNC_PATH="/srv/shop"
  run mage_cmd_sync store
  [[ "$output" == *"store:/srv/shop/pub/media pub/"* ]]
}

@test "also pulls the latest backup with --db" {
  run mage_cmd_sync store --db
  [ "$status" -eq 0 ]
  [[ "$output" == *"rsync -aP store:/data/web/magento2/var/backups/store-20260927-101500.sql.gz var/backups/"* ]]
  [[ "$output" == *"Backup in var/backups/store-20260927-101500.sql.gz"* ]]
  [[ "$output" == *"/pub/media pub/"* ]]
}

@test "asks for the latest backup in the backup dir of the server" {
  SSH_CLI="echo ssh"

  run mage_cmd_sync store --db
  [[ "$output" == *"ssh store ls -t '/data/web/magento2/var/backups'/*.sql.gz"* ]]
}

@test "errors without a backup on the server" {
  SSH_CLI="true"

  run mage_cmd_sync store --db
  [ "$status" -eq 1 ]
  [[ "$output" == *"run 'mage backup' on the server first"* ]]
  [[ "$output" != *"pub/media"* ]]
}

@test "errors when rsync fails" {
  SYNC_RSYNC_CLI="false"

  run mage_cmd_sync store
  [ "$status" -eq 1 ]
  [[ "$output" == *"Could not sync pub/media from store:/data/web/magento2"* ]]
}

@test "uses rsync on the host with warden" {
  function warden() { echo "warden $*"; }
  mage_env_use warden
  SYNC_RSYNC_CLI="echo rsync"

  run mage_cmd_sync store
  [[ "$output" != *"warden"* ]]
}
