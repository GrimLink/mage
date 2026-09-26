# Reindex everything, then flush the cache so the result shows
function mage_cmd_reindex() {
  $MAGENTO_CLI indexer:reindex && $MAGENTO_CLI cache:flush
}
