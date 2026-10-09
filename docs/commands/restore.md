# mage restore

Replace the database with a backup of [`mage backup`](backup.md), unpack its media, and set it up for this device.

```bash
mage restore                                          # the latest backup in var/backups
mage restore ~/Downloads/shop-20260927-101500.sql.gz  # a given backup
mage restore --no-media                               # only the database
```

| Option       | Does                                        |
| ------------ | ------------------------------------------- |
| `--media`    | Unpack the media backup, without asking     |
| `--no-media` | Leave `pub/media` as is, without asking     |

Without a file it takes the newest `.sql.gz` in `MAGE_BACKUP_DIR`, `var/backups` by default.
The media backup is the `-media.tar.gz` with the same name next to it.
When there is one, mage asks whether to unpack it, yes by default.

It shows the project root and asks to type the folder name to confirm, as the current database is dropped.

## Before you restore

Magento must be installed on this device, as the restore keeps its `app/etc/env.php`.
Name the project folder after the live domain, so `store` for `store.nl`.
Then the url of `mage setup` is already the url the default store gets after the restore, `store.test`.

## From a git clone

A clone has no `vendor`, `bin/magento` or `app/etc/env.php`, so mage does not see it as a Magento project yet.
Install the packages, then Magento, then restore:

```bash
git clone <repository> store && cd store

# Local and Valet
composer install

# Warden
warden env-init store magento2 && warden env up
warden env exec php-fpm composer install

# DDEV, with the .ddev folder of the repository
ddev start && ddev composer install

mage setup
mage restore ~/Downloads/store-20260927-101500.sql.gz
```

`mage setup` installs a blank Magento, with a database the restore replaces.
Without the restore, that blank database is a clean start for the project.

`mage setup` disables two factor authentication in `app/etc/config.php`.
To keep the config of the repository, run `git checkout app/etc/config.php` before the restore.

## Steps

1. Imports the dump into the database of `app/etc/env.php`, dropping the current one:
   - **Local and Valet:** `db:import --drop` of magerun2, or `mysql` without it.
   - **Warden:** streams the dump into `mysql` of the `db` container.
   - **DDEV:** `ddev import-db`.
2. Unpacks the media into `pub/media`, when chosen.
   Files that are in `pub/media` but not in the backup stay.
3. Points the config to this device:
   - Every base url keeps its host, with `MAGE_DOMAIN` instead of its tld, and uses https.
     So `store.nl` becomes `store.test`, and `b2b.store.nl` becomes `b2b.store.test`.
   - The link, static and media urls, such as a CDN, are removed, so they follow the base url of their scope.
   - The cookie domain and the custom admin url are removed.
   - The search engine becomes the OpenSearch of this device, with the database name as index prefix.
4. Makes the domain of each store view reachable, the same way as [`mage add store`](add-store.md) does for the environment.
   With Valet it links and secures each domain and adds it to `.valet-env.php`, with Warden it signs the certificate, the others show what to add.
   A domain shared by several store views goes to the default store view of their store.
5. Cleans the cache, and runs `setup:upgrade` when the modules of this device differ from the backup, such as the dev packages.
6. Sets the store config from `MAGE_STORE_CONFIG` and the developer mode.
7. Reindexes and cleans the cache, see [`mage reindex`](reindex.md).

## After the restore

- **Admin users:** those of the backup, with their two factor authentication.
  Add your own with [`mage add admin`](add-admin.md), which is needed after a backup with `--strip="@development"`.
- **Domains:** only the last part of a domain is replaced, so `store.co.uk` becomes `store.co.test`.
