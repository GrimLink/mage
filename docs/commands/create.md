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
4. Requires the default packages from `MAGE_PACKAGES` and `MAGE_DEV_PACKAGES`, see [configuration](../config.md).
5. On Mage-OS, applies the [composer fragment](../composer-fragments.md) `composer-mage-os.json` of the [templates](../templates.md).
   It replaces modules that Mage-OS ships but mage leaves out, so composer never installs them:
   `mage-os/module-passkey-auth`, as it depends on two factor auth, which the setup disables, and `mage-os/module-theme-optimization`, see the setup below.
   Templates synced before this fragment existed are updated first, and without it, it warns and continues.
6. Runs `composer install`.
7. Runs the setup below.

Edition `community` and `enterprise` need your Magento marketplace keys in the composer auth.

## Keeping the Mage-OS modules

To use a replaced module after all, such as `mage-os/module-theme-optimization`:

1. Remove its line from the `replace` of `composer.json`.
2. Require it, with `mage add mage-os/module-theme-optimization`.
3. Enable it, with `mage run module:enable MageOS_ThemeOptimization`, as the setup disables it.

To keep it enabled on the next `mage setup`, leave it out of `MAGE_DISABLE_MODULES` in the [configuration](../config.md):

```bash
# ~/.config/mage/config
MAGE_DISABLE_MODULES=(
  MageOS_PasskeyAuth
  Magento_AdminAdobeImsTwoFactorAuth
  Magento_TwoFactorAuth
)
```

`mage-os/module-passkey-auth` needs two factor auth, so keep that enabled as well, by leaving out the first three.

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
   Sessions go to the database for local and Valet, so they are dropped with it on nuke, and to Redis for DDEV and Warden, which each run their own.
3. Gives OpenSearch and the Redis caches a prefix named after the database, so projects sharing a service stay apart.
4. Sets the store name and the store config from `MAGE_STORE_CONFIG`.
5. Sets the developer mode, and disables the modules in `MAGE_DISABLE_MODULES` the install has: two factor authentication (with `MageOS_PasskeyAuth` on Mage-OS, which depends on it), and on Mage-OS `MageOS_ThemeOptimization`, whose bfcache conflicts with the BFCache patches and does not work with Hyvä, see [mage-os/module-theme-optimization#28](https://github.com/mage-os/module-theme-optimization/issues/28).
6. Writes the `.valet-env.php` with Valet.
7. Moves the `*.sample` files of the root to `dev/sample-files`, and adds a `.gitignore` when the project has none.

At the end it shows the store and admin url, with the admin user and password.
