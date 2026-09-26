# mage add patch

Add patches through [cweagans/composer-patches](https://github.com/cweagans/composer-patches), and apply them right away.

```bash
mage add patch magento/module-theme "Fix the header" patches/header.patch
mage add patch vendor/package Fix https://example.com/fix.patch
mage add patch https://github.com/GrimLink/magento-patch-bfcache
mage add patch
```

It requires `cweagans/composer-patches` (version 2, one of the default packages of `mage create`) and [jq](https://jqlang.org/).

## A single patch

The arguments are the package to patch, the patch name and the patch source, which is always the last one, so the name can be several words. Anything not given is asked.

The patch is added to `patches.json`, the patches file of composer-patches, which is created when missing. A source that is not a url gets the `.patch` extension when it has none.

## A patch repository

A GitHub or GitLab repository url adds all of its patches:

1. Downloads the `main` branch of the repository.
2. Merges its `patches.json` into the one of the project, existing patches stay.
3. Copies its `patches` folder into `patches/`, or the whole repository when it has no such folder.

## Applying

Both end with `composer patches-relock` and `composer patches-repatch`, so the patches are applied immediately.

# mage add bfcache

```bash
mage add bfcache
```

Adds the [BFCache compatibility patches](https://github.com/GrimLink/magento-patch-bfcache), the same as `mage add patch https://github.com/GrimLink/magento-patch-bfcache`.
