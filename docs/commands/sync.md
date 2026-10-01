# mage sync

Pull `pub/media` from a server with rsync, and with `--db` also the latest backup of [`mage backup`](backup.md).

```bash
mage sync app@store.hypernode.io                 # media from /data/web/magento2
mage sync app@store.hypernode.io --db            # also the latest backup
mage sync store /var/www/store                   # a host of ~/.ssh/config, with its own root
```

| Argument or option | Does                                                                   |
| ------------------ | ---------------------------------------------------------------------- |
| `HOST`             | The ssh host of the server, required                                   |
| `PATH`             | The Magento root on the server, `MAGE_SYNC_PATH` by default            |
| `--db`             | Also pull the latest backup of the server into the local `var/backups` |

The host is anything ssh takes, such as `app@store.hypernode.io` or a host of your `~/.ssh/config`.
The root defaults to `/data/web/magento2`, the one of [Hypernode].
For servers with another layout, give the root as second argument, or set `MAGE_SYNC_PATH` in the [configuration](../config.md).

## Media

rsync only copies what changed, so running it again is fast, and an interrupted sync resumes.
It leaves out the folders Magento rebuilds on its own: `catalog/product/cache`, `captcha` and `tmp`.
Local files that are not on the server stay.

## Database

Sync does not dump the database, run `mage backup --no-media` on the server first.
With `--db` it pulls the newest `.sql.gz` from `var/backups` on the server, then restore it with [`mage restore`](restore.md):

```bash
ssh app@store.hypernode.io 'cd /data/web/magento2 && mage backup --no-media'
mage sync app@store.hypernode.io --db
mage restore
```

## Environments

rsync and ssh always run on your machine, also with Warden and DDEV, as that is where your ssh keys are.
The media lands in `pub/media` of the project, which the containers share.

[Hypernode]: https://www.hypernode.com/
