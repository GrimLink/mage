# mage clean

Clean caches and generated files. `mage purge` does the same.

```bash
mage clean
mage clean redis
mage purge opensearch
```

Without an option, or with `all`, it runs the options in `MAGE_CLEAN_ALL`, by default `files`, `redis` and `varnish`, see [configuration](../config.md). `mage clean help` lists the options.

| Option | Does |
|---|---|
| `files` | Empties `generated/code`, `generated/metadata`, `pub/static`, `var/cache`, `var/composer_home`, `var/page_cache` and `var/view_preprocessed`. `pub/static/.htaccess` stays. |
| `redis` | Clears the Redis caches of this project |
| `varnish` | Bans all pages from Varnish, skipped when `varnishadm` is not installed |
| `opensearch` | Deletes the OpenSearch indices of this project, run a reindex afterwards |
| `sample-files` | Moves the `*.sample` files of the root to `dev/sample-files` |
| `logs` | Deletes the logs in `var/log`, not part of `all` |

## Redis

On your machine and with Valet, projects share one Redis. So `redis` only deletes the keys with the cache prefixes of this project, read from `app/etc/env.php`. With Warden and DDEV the Redis belongs to the project, so it is flushed as a whole.

## OpenSearch

The host, port and index prefix come from the Magento config. With Warden and DDEV the request runs inside the OpenSearch container.
