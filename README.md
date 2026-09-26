# Mage

**Mage** is a simple tool built on top of `bin/magento` to enhance your Magento 2 development experience. It provides shortcuts and custom functions to save you time and effort.

## Benefits of Using Mage

* **Easy installation of Magento:** create and install a Mage-OS, Magento Open Source or Adobe Commerce project in one command.
* **Works from anywhere in a project:** run mage from any nested folder, it finds the Magento root on its own.
* **Environment aware:** the same commands work on your machine, with [Laravel Valet], [Warden] and [DDEV].
* **One place to add things:** composer packages, git repositories, composer fragments from a json file, and generators for themes and modules.
* **Everything else goes to `bin/magento`:** any command mage does not know is passed on as is.

## Installation

Download the script:

```bash
curl -O https://raw.githubusercontent.com/GrimLink/mage/main/mage && chmod +x mage
```

Alternatively, use wget:

```bash
wget https://raw.githubusercontent.com/GrimLink/mage/main/mage && chmod +x mage
```

Move it to a folder in your `PATH`, such as `~/.local/bin`. Update it later with `mage self-update`, which also updates the [templates](docs/templates.md).

### Requirements

* **bash** 3.2 or newer, the version macOS ships with is enough.
* **git**, and **curl** or **wget**.
* **[jq]** for `mage add <file>.json` and `mage add patch`, for removing or updating packages by term, and for `mage show modules` and `themes`.
* **php** on your machine is optional, `mage nuke` uses it to read `app/etc/env.php`.

## Commands

Run `mage help` for the full list. Anything mage does not know runs `bin/magento`, so `mage cache:flush` works as expected.

| Command | Does |
|---|---|
| [`create`](docs/commands/create.md) | Create, install and set up a new project |
| [`setup`](docs/commands/create.md#mage-setup) | Reinstall Magento in an existing project |
| [`nuke`](docs/commands/nuke.md) | Permanently delete a project (database, environment, files) |
| [`add`](docs/commands/add.md) | Add a package, git repository, composer fragment or generated code |
| [`add theme`](docs/commands/add-theme.md) | Create a child theme |
| [`add module`](docs/commands/add-module.md) | Create a module |
| [`add hyva`](docs/commands/add-hyva.md) | Add the Hyvä Theme |
| [`add storeinfo`](docs/commands/add-storeinfo.md) | Add the Siteation StoreInfo modules |
| [`add patch`](docs/commands/add-patch.md) | Add a composer patch, or all patches of a repository |
| [`add bfcache`](docs/commands/add-patch.md#mage-add-bfcache) | Add the BFCache compatibility patches |
| [`add admin`](docs/commands/add-admin.md) | Create an admin user |
| [`add customer`](docs/commands/add-admin.md#mage-add-customer) | Create a customer |
| [`add store`](docs/commands/add-store.md) | Create a store view with its own domain |
| [`add i18n`](docs/commands/add-i18n.md) | Collect the phrases of a module or theme |
| [`del`](docs/commands/remove.md) | Remove packages by name or term |
| [`upd`](docs/commands/update.md) | Update packages by name or term |
| [`outdated`](docs/commands/outdated.md) | List the direct dependencies with a newer version |
| [`watch`](docs/commands/watch.md) | Clean only the caches a file change affects |
| [`reindex`](docs/commands/reindex.md) | Reindex, then flush the cache |
| [`clean`](docs/commands/clean.md) | Clean caches and generated files (alias: `purge`) |
| [`open`](docs/commands/open.md) | Open a store view or the admin in your browser |
| [`show`](docs/commands/show.md) | Show project information, such as the stores |
| [`run`](docs/commands/run.md) | Run [n98-magerun2] |
| `help`, `version`, `self-update` | Show help, show the version, update mage |

### Working from a nested folder

Mage looks for the Magento root (the folder with `bin/magento` and `app/etc/di.xml`) from the current folder upwards, and runs from there. So `mage cache:flush` works from `app/code/Vendor/Module` too. Outside a project only `create`, `setup`, `help`, `version` and `self-update` work.

## Configuration

Mage runs with sensible defaults, all of which can be changed in `~/.config/mage/config`. See [configuration](docs/config.md).

## Supported Platforms

Mage works on **macOS** and **most Linux platforms**, and detects these environments on its own, see [environments](docs/environments.md):

* **Local:** services such as MySQL and OpenSearch on your machine.
* **[Laravel Valet]**
* **[Warden]:** supported with thanks to [@tdgroot](https://github.com/tdgroot).
* **[DDEV]**

## Contributing

We welcome contributions to Mage! Fork the repository, make your changes, and submit a pull request. See [development](docs/development.md) for how the source is organised, built and tested.

## License

Mage is licensed under the MIT License. See the LICENSE file for details.

[n98-magerun2]: https://github.com/netz98/n98-magerun2
[jq]: https://jqlang.org/
[Laravel Valet]: https://laravel.com/docs/valet
[Warden]: https://github.com/wardenenv/warden
[DDEV]: https://ddev.com/
