load helper

function setup() {
  load_mage
  MAGENTO_CLI="echo magento"
}

@test "reindexes all and flushes the cache" {
  run mage_cmd_reindex
  [ "$output" = "$(printf 'magento indexer:reindex\nmagento cache:flush')" ]
}

@test "reindexes the given indexes" {
  run mage_cmd_reindex catalogsearch_fulltext cataloginventory_stock
  [ "${lines[0]}" = "magento indexer:reindex catalogsearch_fulltext cataloginventory_stock" ]
}

@test "does not flush when the reindex fails" {
  MAGENTO_CLI="false"

  run mage_cmd_reindex
  [ "$status" -ne 0 ]
}
