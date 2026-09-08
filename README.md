# Mage

**Mage** is a simple tool built on top of `bin/magento` to enhance your Magento 2 development experience. It provides shortcuts and custom functions to save you time and effort.

## Benefits of Using Mage

* **Easy Installation of Magento**: install any version and distribution.
* **Easier commands:** Mage introduces shorter aliases for common `bin/magento` commands, saving you keystrokes.
* **Custom functions:** Mage offers helper commands like `reindex` and `purge` for specific tasks.
* **Open stores quickly:** Open your default store or specific store views with `mage open`.
* **Efficient development:** The `watch` command automates cache cleaning on file changes, improving your workflow.
* **Easier patch creation**: Create patches with only a few arguments.
* **BFCache compatibility**: Easily add [BFCache compatibility patches] to your project.
* **Isolated services**: Every project gets its own Redis instance and OpenSearch index prefix, so one `cache:flush` or reindex cannot reach another project.

## Installation

Download the script:

```bash
wget https://raw.githubusercontent.com/GrimLink/mage/main/mage && chmod +x mage
```

Alternatively, use curl:

```bash
curl -O https://raw.githubusercontent.com/GrimLink/mage/main/mage && chmod +x mage
```

## Available Commands

For a complete list of commands, run `mage help` or view the [src/_info.sh](https://github.com/GrimLink/mage/blob/main/src/_info.sh) source. 

Here are some highlights of what Mage can do:

### Setup & Management
* **`mage create`**: Quickly scaffold and install a new Magento 2 project.
* **`mage nuke`**: Permanently delete the local Magento project (Database, Environment, Files).
* **`mage add [PKG|GIT_URL]`**: An enhanced `composer require` that also accepts raw git repository URLs.
* **`mage outdated`**: Easily view all direct outdated composer dependencies.

### Service Isolation

By default a Magento project uses Redis db 0, 1 and 2 on port 6379, and falls back to the `magento2` OpenSearch index prefix. Run more than one project on a machine and they share all of it: a `cache:flush` clears the cache of every project at once, a reindex overwrites the indices of another project, and importing a production database drags its index prefix along with it.

* **`mage isolate`:** Give the current project its own Redis instance and pin its search config in `app/etc/env.php`, where a database import cannot overwrite it.
* **`mage isolate all [PATH]`:** Do the same for every Magento project below `PATH`.
* **`mage isolate status [PATH]`:** Show the Redis instance and index prefix of every project, and flag the ones that share either.
* **`mage isolate start|stop`:** Start or stop the Redis instance of every project.
* **`mage isolate agent`:** Install a launchd or systemd unit that starts those instances at login.
* **`mage isolate prune [PATH]`:** Delete the OpenSearch indices that no project claims.

New projects are isolated by `mage setup` already. The port of each project is kept in `~/.config/mage/redis-ports.tsv`.

**Note:** Warden gives every project its own containers, so isolation is skipped there. Set `MAGE_ISOLATE=0` to opt out everywhere else.

### Store & Theme Development
* **`mage new store [url|prefix]`:** Programmatically create a new store view and configure its base URLs and routing (e.g., `mage new store luma` or `mage new store b2b.example.test`).
* **`mage new patch`:** Create a composer patch with ease.
* **`mage add bfcache`:** Automatically fetch and vendor [BFCache compatibility patches] for your project.
* **`mage set mage-os`:** Easily replace the standard Magento 2 distro with the Mage-OS distro.

### Daily Workflow
* **`mage open [storeview]`:** Open your default store or a specific store based on the `storeview` name. Use `admin` instead of `storeview` to open the admin panel.
* **`mage watch`:** A shortcut for [Mage-OS Cache Clean] that monitors Magento 2 file changes and clears only the affected cache automatically.
* **`mage purge`:** Clears all static generated files and caches. Useful for troubleshooting or forcing a hard reload.
* **`mage run [action]`:** Runs [n98-magerun2] commands.

**Note:**

* `mage run` requires the [n98-magerun2] module
* Commands with "hyva" require a [Hyvä license] or GitLab access
* `mage watch` requires the [Mage-OS Cache Clean] module
* `set theme` and `set hyva` requires the [Yireo_ThemeCommands] module

### Supported Platforms

Mage works without additional configuration on:

* **macOS**
* **Most Linux platforms**
* **[Laravel Valet]**
* **[Warden]:** Supported with thanks to [@tdgroot](https://github.com/tdgroot)

## Contributing

We welcome contributions to Mage! Fork the repository, make your changes, and submit a pull request.

## License

Mage is licensed under the MIT License. See the LICENSE file for details.

[n98-magerun2]: https://github.com/netz98/n98-magerun2
[Hyvä license]: https://www.hyva.io/hyva-themes-license.html
[Yireo_ThemeCommands]: https://github.com/yireo/Yireo_ThemeCommands
[Mage-OS Cache Clean]: https://github.com/mage-os/magento-cache-clean
[Laravel Valet]: https://laravel.com/docs/valet
[Warden]: https://github.com/wardenenv/warden
[Siteation]: https://siteation.dev/
[BFCache compatibility patches]: https://github.com/GrimLink/magento-patch-bfcache
