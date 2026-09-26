# mage show

Show information about the project.

```bash
mage show stores
mage show stores --format=json
mage show modules
```

`mage show help` lists the options. Without an option it stops with an error and the same list.

| Option | Does |
|---|---|
| `stores` | Lists the stores with their base urls, through [n98-magerun2](https://github.com/netz98/n98-magerun2). Further arguments go to magerun. |
| `modules` | Lists the modules of your direct dependencies and `app/code`, with where they come from |

## modules

Like [`mage outdated`](outdated.md), only the direct dependencies in `composer.json` count, `require-dev` included. So the modules they pull in, such as those of Magento itself, stay out, and a metapackage adds none.

Mage finds the module names in the `registration.php` files of each package, up to three folders deep, so a package with several modules lists them all. Themes and libraries are skipped. A module disabled in `app/etc/config.php` is marked as such.

This requires [jq](https://jqlang.org/).
