# mage outdated

List the direct dependencies that have a newer version.

```bash
mage outdated
mage outdated --terminal
mage outdated --terminal --minor-only
```

By default the result is written as json to `composer-outdated.json` in the project root, which the gitignore template ignores. With `--terminal` it is shown instead.

It runs `composer outdated --direct --no-dev`, leaving out the packages in `MAGE_OUTDATED_IGNORE`. By default those are `symfony/finder` and `symfony/process`, which Magento pins, see [configuration](../config.md). Further arguments go to composer.
