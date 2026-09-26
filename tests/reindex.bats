load helper

function setup() {
  load_mage
  MAGENTO_CLI="echo magento"
}

@test "reindexes all and flushes the cache" {
  run mage_cmd_reindex
  [ "$output" = "$(printf 'magento indexer:reindex\nmagento cache:flush')" ]
}

@test "does not flush when the reindex fails" {
  MAGENTO_CLI="false"

  run mage_cmd_reindex
  [ "$status" -ne 0 ]
}
