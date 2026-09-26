# mage reindex

Reindex, then flush the cache so the result shows.

```bash
mage reindex
mage reindex catalogsearch_fulltext cataloginventory_stock
```

Without arguments it reindexes everything. Index names go to `bin/magento indexer:reindex`, see `mage indexer:info` for the names. The cache is only flushed when the reindex succeeds.
