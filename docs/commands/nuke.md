# mage nuke

Permanently delete the project: its search indices, cache, database, environment and files. `mage destroy` does the same.

```bash
mage nuke
mage nuke --keep-files
```

| Option | Does |
|---|---|
| `--keep-files` | Keep the project files, only remove the services |

It shows the project root and asks to type the folder name to confirm, also when run from a nested folder.

## Steps

The database name and credentials come from `app/etc/env.php`, which needs php on your machine. Without it, the folder name and the [configuration](../config.md) are used.

* **Local and Valet:** clears the OpenSearch indices and Redis keys of the project only, then drops the database. Valet also unsecures the site and unlinks its extra stores.
* **Warden:** `warden env down -v`, which removes the database and indices with the volumes.
* **DDEV:** `ddev delete --omit-snapshot --yes`.

Then the project folder is removed, unless `--keep-files` is given. Your shell is still in the removed folder afterwards, so `cd ..`.
