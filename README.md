# Mage

**Mage** is a simple tool built on top of `bin/magento` to enhance your Magento 2 development experience. It provides shortcuts and custom functions to save you time and effort.

## Benefits of Using Mage

* **Easier commands:** Mage introduces shorter aliases for common `bin/magento` commands, saving you keystrokes.
* **Custom functions:** Mage offers helper commands like `reindex` and `purge` for specific tasks.
* **Open stores quickly:** Open your default store or specific store views with `mage open`.
* **Efficient development:** The `watch` command automates cache cleaning on file changes, improving your workflow.

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

For a complete list, run `mage help`, or view the [src/_info.sh](https://github.com/GrimLink/mage/blob/main/src/_info.sh). Here are some highlights:

* **`mage open [storeview]`:** Open your default store or a specific store based on the `storeview` name. You can also use `admin` instead of `storeview`, to open the admin panel.
* **`mage watch`:** This alias for [mage2tv Cache Clean] monitors for Magento 2 file changes and clears only the affected cache, streamlining development.
* **`mage purge`:** This command clears all static generated files and caches, useful for troubleshooting or forcing a hard reload.
* **`mage set mage-os`:** Easily replace Magento2 distro with the Mage-OS distro
* **`mage outdated`:** Show all direct outdated composer dependencies
* **`mage run [action]`:** Runs [n98-magerun2] commands

**Note:**

* `mage run` requires the [n98-magerun2] module
* Commands with "hyva" require a [Hyvä license] or GitLab access
* `set theme` and `set hyva` requires the [Yireo_ThemeCommands] module
* `set baldr` requires the [Siteation] Baldr Theme

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
[mage2tv Cache Clean]: https://github.com/mage2tv/magento-cache-clean
[Laravel Valet]: https://laravel.com/docs/valet
[Warden]: https://github.com/wardenenv/warden
[Siteation]: https://siteation.dev/
