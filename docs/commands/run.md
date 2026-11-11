# mage run

Run [n98-magerun2] in the project, with all arguments passed on as is.

```bash
mage run sys:info
mage run db:console
mage run dev:console
mage run cache:list
mage run sys:store:list --format=json
```

Every option goes straight to magerun, so `mage run list` shows all its commands
and `mage run help db:dump` the options of one of them.
Mage adds nothing of its own, it picks the right magerun for your environment, so the same command works in every project.

## Which magerun it uses

- **Local and Valet:** `magerun2` or `n98-magerun2` on your machine, whichever responds first.
- **Warden:** `n98-magerun` in the `php-fpm` container, with the PHP and database of the project.
- **DDEV:** the magerun on your machine, see the requirements below.

Mage only looks for magerun when a command needs it, as the version check is slow in a Magento root.

## Other commands that use magerun

- [`mage backup`](backup.md) dumps the database with `db:dump`, or with `mysqldump` without magerun.
- [`mage restore`](restore.md) imports a dump with `db:import`, or with `mysql` without magerun.
- [`mage add customer`](add-admin.md#mage-add-customer) creates a customer with `customer:create`.

## Requirements

Install [n98-magerun2] on your machine. Warden has it in the container already.
When magerun is missing, or does not run on your PHP version, `mage run` stops and tells you so.

With DDEV, the magerun on your machine cannot reach the database in the container,
so commands like `db:console` only work when you run magerun inside DDEV yourself.

[n98-magerun2]: https://github.com/netz98/n98-magerun2
