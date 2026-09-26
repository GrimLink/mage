# Environments

Mage detects how a project runs, and runs its commands the matching way.
The first environment that matches wins, in this order:

| Environment                                     | Detected when                                            | Commands run                                          |
| ----------------------------------------------- | -------------------------------------------------------- | ----------------------------------------------------- |
| [Warden](https://github.com/wardenenv/warden)   | `warden` is installed and `.env` holds `WARDEN_ENV_NAME` | In the `php-fpm` container, through `warden env exec` |
| [DDEV](https://ddev.com/)                       | `ddev` is installed and `.ddev/config.yaml` exists       | In the web container, through `ddev`                  |
| [Laravel Valet](https://laravel.com/docs/valet) | `valet` is installed                                     | On your machine                                       |
| Local                                           | Always                                                   | On your machine                                       |

Inside a Warden or DDEV container their command is not installed, so mage runs there as local.

When creating a project, there is nothing to detect yet.
`mage create` asks which environment to use, defaulting to the first one installed, or takes `--env=warden`, `--env=ddev`, `--env=valet` or `--env=local`.

## Local

Everything runs on your machine: `bin/magento`, composer, and the services MySQL, OpenSearch and Redis.
The connection settings come from the [configuration](config.md), by default `root`/`root` on `localhost`.

- **Setup:** creates the database with `mysql`, named after the project folder.
- **Nuke:** clears the OpenSearch indices and Redis keys of the project, and drops its database.
- **Add store:** tells you to point the new domain to the project yourself.
- **Open mail:** opens `MAGE_MAIL_URL`, Mailpit on `http://localhost:8025` by default.
- **Watch:** without cache-clean in the project, uses `cache-clean.js` from your `PATH`.
- **Redis:** projects share one Redis, so every project gets its own cache prefix and only its own keys are cleaned.

## Valet

Works like local, and adds:

- **Setup:** secures the site with `valet secure`, and writes a `.valet-env.php` with the default store and a commented example for a second store.
- **Nuke:** unsecures the site, and unsecures and unlinks every extra store from `.valet-env.php`.
- **Add store:** adds the store to `.valet-env.php`, then links and secures it.

## Warden

- **Services:** the database is `magento`/`magento` on host `db`, OpenSearch is `opensearch` and Redis is `redis`, the config settings do not apply.
- **Create:** runs `warden env-init` and `warden env up`, then creates the composer project inside the container.
- **Setup:** signs the certificate with `warden sign-certificate`.
- **Clean:** flushes the Redis of the project, which is its own.
- **Nuke:** `warden env down -v`, removing the containers and their volumes with the database and indices.
- **Add store:** signs the certificate, and tells you how to route the domain.
- **Open mail:** opens the global Mailpit at `https://webmail.warden.test/`.
- **Watch:** without cache-clean in the project, uses the one in the global composer folder of the container.

## DDEV

- **Services:** the database is `db`/`db`/`db` on host `db`, OpenSearch is `opensearch` and Redis is `redis`, the config settings do not apply.
  Stores use the `ddev.site` domain.
- **Create:** follows the [DDEV Magento quickstart](https://docs.ddev.com/en/stable/users/quickstart/#magento-2): `ddev config` with the `magento2` project type and settings management off, the OpenSearch and Redis add-ons, `ddev start`, then the composer project.
- **Setup:** nothing to prepare, DDEV provides the database and certificate.
- **Clean:** flushes the Redis of the project, which is its own.
- **Nuke:** `ddev delete --omit-snapshot --yes`.
- **Add store:** tells you how to add the domain to DDEV.
- **Open mail:** `ddev launch -m`.
- **Watch:** needs cache-clean in the project.

Note that `mage run` uses the magerun on your machine for DDEV, which cannot reach the DDEV database.
