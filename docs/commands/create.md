# mage create

Create a new project, install it and set it up, in a new folder.

```bash
mage create my-shop
mage create my-shop --edition=community --version=2.4.8 --env=warden
mage create my-shop --template=composer-create-agency.json
mage create my-shop -y
```

| Option                | Does                                                                            |
| --------------------- | ------------------------------------------------------------------------------- |
| `--edition=EDITION`   | One of the [editions](#editions), defaults to `MAGE_EDITION` (`mage-os-mirror`) |
| `--version=VERSION`   | The Magento version, defaults to `latest`                                       |
| `--env=ENV`           | `warden`, `ddev`, `valet` or `local`, defaults to the first one installed       |
| `--template=TEMPLATE` | One of the [templates](#templates) or a json file, defaults to one by edition   |
| `-y`, `--yes`         | Use the defaults for anything not given, instead of asking                      |

Anything not given as an option is asked, except the template.
It requires [jq](https://jqlang.org/).
The edition and environment are picked from a numbered list, by number or name.
The name is a folder name, and must not exist yet.

## Editions

| Edition           | Package                              | Repository                    |
| ----------------- | ------------------------------------ | ----------------------------- |
| `mage-os-mirror`  | `magento/project-community-edition`  | `https://mirror.mage-os.org/` |
| `mage-os`         | `mage-os/project-community-edition`  | `https://repo.mage-os.org/`   |
| `mage-os-minimal` | `mage-os/project-minimal-edition`    | `https://repo.mage-os.org/`   |
| `community`       | `magento/project-community-edition`  | `https://repo.magento.com/`   |
| `enterprise`      | `magento/project-enterprise-edition` | `https://repo.magento.com/`   |

`mage-os-mirror` is the default.
It is Magento Open Source from the Mage-OS mirror, so it needs no Magento marketplace keys, and it is the same code the extensions and patches you add are made for.
`mage-os` is the Mage-OS distribution, which adds its own modules on top.
`mage-os-minimal` is Mage-OS with a smaller set of modules.

## Templates

A template is a [composer fragment](../composer-fragments.md) that sets up the packages of a new project.
Without `--template`, it uses `MAGE_CREATE_TEMPLATE` from the [configuration](../config.md), or when that is empty, the one of the edition: `mage-os` for the `mage-os` edition, `default` for the others.

| Template  | Bundled as                     | Adds                                                              |
| --------- | ------------------------------ | ----------------------------------------------------------------- |
| `default` | `composer-create-default.json` | The default packages                                              |
| `mage-os` | `composer-create-mage-os.json` | The default packages, and replaces two Mage-OS modules, see below |

The default packages are `cweagans/composer-patches` (for [`mage add patch`](add-patch.md)), `yireo/magento2-theme-commands` (to switch themes, see [`mage add hyva`](add-hyva.md)), `swissup/module-ignition` and `community-engineering/language-nl_nl`.
The dev packages are `avstudnitz/scopehint2` and `siteation/magento2-debugbar`.
Each is required as its latest version.

A path to a json file uses your own template, such as a copy of a bundled one from `~/.config/mage/templates`.
Its `{{NAME}}` placeholders are asked, like any fragment.

`MAGE_PACKAGES` and `MAGE_DEV_PACKAGES` are deprecated and will be dropped.
They are empty now, and when your configuration still sets them, they are required after the template, with a warning.
Move them to your own template.

## Steps

1. Creates the composer project, in the chosen [environment](../environments.md).
   Warden and DDEV first set up and start their containers.
2. Configures composer for development: `minimum-stability` dev with `prefer-stable`.
3. Registers the `package-source` folder as a composer path repository, for your local packages.
   It gets a `.gitkeep`, so the folder survives a clone, which `composer install` needs.
4. Applies the [template](#templates), with its packages only written to `composer.json`.
   A template that can not be found stops the command before the project is created.
5. Requires `MAGE_PACKAGES` and `MAGE_DEV_PACKAGES`, when your configuration still sets them.
6. Runs `composer install`.
7. Runs the setup below.
8. Generates the XML catalog of the Magento schemas in `.vscode/catalog.xml`, for VS Code and Zed, see [XML catalog](../xml-catalog.md).

Edition `community` and `enterprise` need your Magento marketplace keys in the composer auth.

## The Mage-OS modules

The `mage-os` template replaces two modules Mage-OS ships, so composer never installs them:

- `mage-os/module-passkey-auth`, as it depends on two factor auth, which the setup disables.
- `mage-os/module-theme-optimization`, whose bfcache conflicts with the BFCache patches and does not work with Hyvä, see [mage-os/module-theme-optimization#28](https://github.com/mage-os/module-theme-optimization/issues/28).

To use one after all, remove its line from the `replace` of `composer.json`, and require it, such as with `mage add mage-os/module-theme-optimization`.
`mage-os/module-passkey-auth` needs two factor auth, so empty `MAGE_DISABLE_MODULES` in the [configuration](../config.md) to keep both enabled:

```bash
# ~/.config/mage/config
MAGE_DISABLE_MODULES=()
```

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
4. Sets the store name and the store config from `MAGE_STORE_CONFIG`, and locks the one from `MAGE_ENV_CONFIG` in `app/etc/env.php`.
5. Sets the developer mode, and disables the modules in `MAGE_DISABLE_MODULES` the install has: two factor authentication, with `MageOS_PasskeyAuth`, which depends on it.
   The passkeys are only there in Mage-OS projects created before the `mage-os` template replaced them, so `MageOS_PasskeyAuth` will be removed from the list.
6. Writes the `.valet-env.php` with Valet.
7. Moves the `*.sample` files of the root to `dev/sample-files`, and adds a `.gitignore` when the project has none.

At the end it shows the store and admin url, with the admin user and password.
