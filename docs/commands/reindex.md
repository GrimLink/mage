# mage reindex

Reindex everything, then flush the cache so the result shows.

```bash
mage reindex
```

It is a shortcut for `bin/magento indexer:reindex` followed by `bin/magento cache:flush`, the cache is only flushed when the reindex succeeds.
Arguments are ignored, use `mage indexer:reindex` to reindex specific indexes.
