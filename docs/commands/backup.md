# mage backup

Back up the database, and optionally the media, to set the project up on another device.
The code is left to git.

```bash
mage backup                          # asks whether to include pub/media
mage backup --media                  # database and media
mage backup --no-media               # only the database
mage backup --strip="@development"   # also leave out customers, orders and admins
mage backup --strip=                 # the whole database
```

| Option             | Does                                                                         |
| ------------------ | ---------------------------------------------------------------------------- |
| `--media`          | Include `pub/media`, without asking                                          |
| `--no-media`       | Leave `pub/media` out, without asking                                        |
| `--strip=[GROUPS]` | The magerun2 table groups to leave out of the dump, `@stripped` by default   |

The backup goes to `var/backups` in the Magento root, which the Magento `.gitignore` already ignores:

- `<project>-<date>-<time>.sql.gz`: the database.
- `<project>-<date>-<time>-media.tar.gz`: `pub/media`, when included.

Both can be changed in the [configuration](../config.md), with `MAGE_BACKUP_DIR` and `MAGE_BACKUP_STRIP`.

## Database

With [n98-magerun2] installed, mage runs `db:dump`, so the `--strip` groups of magerun2 work.
The default `@stripped` leaves out the logs and sessions.
Use `@development` for a copy without customers, orders and admin users, then create an admin with [`mage add admin`](add-admin.md) after the import.
Run `mage run db:dump --help` for all groups.
Magerun2 also replaces the definers of the triggers with the current user, as the original user does not exist on another device.

Without magerun2 it falls back to `mysqldump`, with the credentials of `app/etc/env.php`.
That dumps the whole database, and removes the definers too.

- **Local and Valet:** magerun2 or mysqldump on your machine.
- **Warden:** the magerun of the `php-fpm` container.
- **DDEV:** `ddev export-db`, which always exports the whole database.

## Media

The archive leaves out the folders Magento rebuilds on its own: `catalog/product/cache`, `captcha` and `tmp`.

## On a server

Mage needs no environment of its own on a server, such as [Hypernode], it runs there as local.
Install mage on the server, and run `mage backup` from the project.
Over SSH, mage shows the `rsync` command to copy the backup to your device.
With `-P` an interrupted copy resumes where it stopped, so run it again when the connection drops.

## Using the backup

Copy the backup to `var/backups` of the project on the other device, and run [`mage restore`](restore.md).
[`mage sync --db`](sync.md) pulls the latest backup from a server into it.

[n98-magerun2]: https://github.com/netz98/n98-magerun2
[Hypernode]: https://www.hypernode.com/
