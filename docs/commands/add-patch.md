# mage add patch

Add patches through [cweagans/composer-patches](https://github.com/cweagans/composer-patches), and apply them right away. What it does depends on the input:

```bash
mage add patch magento/module-theme                                        # create one from your changes
mage add patch https://github.com/GrimLink/magento-patch-bfcache           # all patches of a repository
mage add patch magento/module-theme "Fix the header" patches/header.patch  # an existing patch
```

Without arguments it asks for the package or repository url. It requires `cweagans/composer-patches` (version 2, one of the default packages of `mage create`) and [jq](https://jqlang.org/).

## Creating a patch from your changes

With only a package:

1. Mage tracks `vendor/<package>` with a temporary git repository.
2. You make your changes in that folder, then press any key.
3. The changes, new files included, are saved as `patches/<package>/LOCAL-<vendor>-<name>.patch`, and the temporary repository is removed.
4. The patch is added as `Local: <vendor>-<name>`.

A second local patch for the same package gets a number, so the first stays. Without changes no patch is created. A package you manage yourself is refused, change it directly instead: one that is a git repository, or one linked from a path repository such as `package-source`.

## A patch repository

A GitHub or GitLab repository url adds all of its patches:

1. Downloads the `main` branch of the repository.
2. Merges its `patches.json` into the one of the project, existing patches stay.
3. Copies its `patches` folder into `patches/`, or the whole repository when it has no such folder.

## An existing patch

A package with a name and a source adds that patch. The source is always the last argument, so the name can be several words, and without a name it is asked. A source that is not a url gets the `.patch` extension when it has none.

## Applying

The patches are kept in `patches.json`, which is created when missing. Every form ends with `composer patches-relock` and `composer patches-repatch`, so the patches are applied immediately.

# mage add bfcache

```bash
mage add bfcache
```

Adds the [BFCache compatibility patches](https://github.com/GrimLink/magento-patch-bfcache), the same as `mage add patch https://github.com/GrimLink/magento-patch-bfcache`.
