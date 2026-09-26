# mage show

Show information about the project.

```bash
mage show stores
mage show stores --format=json
mage show modules
mage show themes
mage show fpc
```

`mage show help` lists the options. Without an option it stops with an error and the same list.

| Option | Does |
|---|---|
| `stores` | Lists the stores with their base urls, through [n98-magerun2](https://github.com/netz98/n98-magerun2). Further arguments go to magerun. |
| `modules` | Lists the modules of your direct dependencies and `app/code`, with where they come from |
| `themes` | Lists the themes of your direct dependencies and `app/design`, with where they come from and their parent |
| `fpc` | Shows the full page cache in use, `builtin` or `varnish`, the counterpart of [`mage set fpc`](set.md) |

## modules and themes

Like [`mage outdated`](outdated.md), only the direct dependencies in `composer.json` count, `require-dev` included. So the modules and themes they pull in, such as those of Magento itself, stay out, and a metapackage adds none. The local ones come from `app/code` and `app/design`.

Mage finds them by the `registration.php` files of each package, up to three folders deep, so a package with several modules or themes lists them all.

* `modules` marks a module disabled in `app/etc/config.php`.
* `themes` shows the parent from the `theme.xml` of each theme.

This requires [jq](https://jqlang.org/).
