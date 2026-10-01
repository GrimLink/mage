# mage reindex

Reindex everything, then clean the cache so the result shows.

```bash
mage reindex
```

It is a shortcut for `bin/magento indexer:reindex` followed by `bin/magento cache:clean`, the cache is only cleaned when the reindex succeeds.
Arguments are ignored, use `mage indexer:reindex` to reindex specific indexes.
