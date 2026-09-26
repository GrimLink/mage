# mage add

Add something to the project. The first argument decides what, in this order:

| Argument | Does |
|---|---|
| A handler name | Runs the handler, see below |
| A path ending in `.json` | Applies a [composer fragment](../composer-fragments.md) |
| A git url ending in `.git` | Clones the repository into `package-source` and requires it |
| Anything else | Runs `composer require` with all arguments as is |

`mage add` without arguments shows this overview with every handler, and `mage add help` does the same.

## Handlers

| Handler | Does |
|---|---|
| [`theme`](add-theme.md) | Create a child theme |
| [`module`](add-module.md) | Create a module |
| [`hyva`](add-hyva.md) | Add the Hyvä Theme |
| [`storeinfo`](add-storeinfo.md) | Add the Siteation StoreInfo modules |

## Composer packages

```bash
mage add vendor/package
mage add vendor/package:^2.0 --dev
```

Mage passes everything to `composer require`, so composer handles the versions, options and errors.

## Git repositories

```bash
mage add git@github.com:Siteation/magento2-storeinfo.git
mage add git@github.com:vendor/package.git --dev
```

For ssh urls ending in `.git`:

1. Clones the repository into `package-source/<vendor>/<name>`, using the name from its `composer.json`. An existing clone with the same url is reused.
2. Registers `package-source` as a composer path repository, when the project does not have it yet.
3. Requires it as `<name>:dev-<branch> as <latest tag>`, so packages that depend on a version of it still resolve. Without tags it requires `<name>:@dev`.

Further arguments, such as `--dev`, go to composer.

## Composer fragments

```bash
mage add composer-hyva.json
```

Applies the repositories, config, auth and packages of a json file, see [composer fragments](../composer-fragments.md).
