# FAQ

## Does mage replace Warden, DDEV or Valet?

No.
Mage is a wrapper, not a development environment.
It does not run PHP, MySQL, OpenSearch, Redis or a web server, and it does not ship containers.
Those come from your own setup: [Warden](https://github.com/wardenenv/warden), [DDEV](https://ddev.com/), [Laravel Valet](https://laravel.com/docs/valet), or services installed on your machine.

Mage detects which of these a project uses, and runs its commands the matching way, such as through `warden env exec` or `ddev`.
So you keep your setup, and get the same commands in every project.
See [environments](environments.md).

## Do I still need my dev setup?

Yes.
Install and configure Warden, DDEV, Valet or the local services first, as their own docs describe.
Mage only calls their commands, it does not install, update or configure them for you.

Some commands drive the environment for a project, by running its own commands.
`mage create` runs `warden env-init` and `warden env up`, or `ddev config` and `ddev start`, and `mage nuke` removes them again.
The tool itself must already be installed.

## Can I keep using the commands of my dev setup?

Yes.
Mage does not change how Warden, DDEV or Valet work, so `warden shell`, `ddev ssh` and the rest work as before.
Use mage where it saves you typing, and the tools themselves for everything else.

## My dev setup is not supported, can I still use mage?

Partly.
Without a detected environment, mage runs as local, so commands run on your machine.
If your PHP and services do not run there, commands that need them will fail.
See [environments](environments.md) for what is detected, and [development](development.md) to add an environment.

## Does mage replace magerun2?

No.
Mage is not a replacement for [n98-magerun2](https://github.com/netz98/n98-magerun2), and does not ship it.
[`mage run`](commands/run.md) passes its arguments to the magerun you have installed, as is.

Mage uses magerun where it does the job well:

- [`mage backup`](commands/backup.md) dumps the database with it, leaving out the table groups of `--strip`.
- [`mage restore`](commands/restore.md) imports the database with it.
- [`mage show stores`](commands/show.md) lists the stores with it.

## Do I need magerun2 installed?

Only for the commands that use it.
Install `magerun2` or `n98-magerun2` yourself, mage picks whichever works first.
Without it, `mage backup` falls back to `mysqldump` and `mage restore` to `mysql`, while `mage run` and `mage show stores` stop with an error.

With Warden, mage uses the magerun of the `php-fpm` container.
With DDEV, `mage run` uses the magerun on your machine, which cannot reach the DDEV database.

## How do mage and magerun2 differ?

Both work on a Magento project, but with a different focus.
Magerun is a large toolbox of Magento commands, run where PHP runs.
Mage is a small layer over `bin/magento` and your dev setup, with shortcuts for daily work, such as creating a project, adding packages and themes, or cleaning only the affected caches.
Use both, mage calls magerun where it helps.

## Does mage replace bin/magento?

No.
Any command mage does not know goes to `bin/magento`, so `mage cache:clean` runs `bin/magento cache:clean` in the right environment.
