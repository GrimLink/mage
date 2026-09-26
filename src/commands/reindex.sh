# Reindex everything, then clean the cache so the result shows.
# cache:clean removes the entries of this project, where cache:flush would empty
# a Redis database that other projects share.
function mage_cmd_reindex() {
  $MAGENTO_CLI indexer:reindex && $MAGENTO_CLI cache:clean
}
