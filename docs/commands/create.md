# mage create

Create a new project, install it and set it up, in a new folder.

```bash
mage create my-shop
mage create my-shop --edition=community --version=2.4.8 --env=warden
mage create my-shop -y
```

| Option              | Does                                                                           |
| ------------------- | ------------------------------------------------------------------------------ |
| `--edition=EDITION` | `mage-os`, `community` or `enterprise`, defaults to `MAGE_EDITION` (`mage-os`) |
| `--version=VERSION` | The Magento version, defaults to `latest`                                      |
| `--env=ENV`         | `warden`, `ddev`, `valet` or `local`, defaults to the first one installed      |
| `-y`, `--yes`       | Use the defaults for anything not given, instead of asking                     |

Anything not given as an option is asked.
The name is a folder name, and must not exist yet.

## Steps

1. Creates the composer project, in the chosen [environment](../environments.md).
   Warden and DDEV first set up and start their containers.
2. Configures composer for development: `minimum-stability` dev with `prefer-stable`, and allows the composer patches plugin.
3. Registers the `package-source` folder as a composer path repository, for your local packages.
   It gets a `.gitkeep`, so the folder survives a clone, which `composer install` needs.
4. Requires the default packages from `MAGE_PACKAGES` and `MAGE_DEV_PACKAGES`, see [configuration](../config.md), and runs `composer install`.
5. Runs the setup below.

Edition `community` and `enterprise` need your Magento marketplace keys in the composer auth.

# mage setup

Install Magento in an existing project, which is also how a project is reinstalled.

```bash
mage setup           # in the project
mage setup my-shop   # from the parent folder
```

When Magento is already installed, it asks first, as this drops the database.

## Steps

1. Prepares the services, depending on the environment: creates the database for local and Valet, secures the site with Valet or signs the certificate with Warden.
2. Runs `setup:install`, with the database, OpenSearch and Redis of the environment.
   The admin url is `<project>_admin`, the store url `https://<project>.<MAGE_DOMAIN>/`.
3. Gives OpenSearch and the Redis caches a prefix named after the database, so projects sharing a service stay apart.
4. Sets the store name and the store config from `MAGE_STORE_CONFIG`.
5. Sets the developer mode, and disables the modules in `MAGE_DISABLE_MODULES` the install has: two factor authentication, and on Mage-OS `MageOS_ThemeOptimization`, whose bfcache conflicts with the BFCache patches and does not work with Hyvä, see [mage-os/module-theme-optimization#28](https://github.com/mage-os/module-theme-optimization/issues/28).
6. Writes the `.valet-env.php` with Valet.
7. Moves the `*.sample` files of the root to `dev/sample-files`, and adds a `.gitignore` when the project has none.

At the end it shows the store and admin url, with the admin user and password.
