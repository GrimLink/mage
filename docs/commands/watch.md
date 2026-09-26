# mage watch

Watch the files of the project, and clean only the caches a change affects, with [Mage-OS Cache Clean](https://github.com/mage-os/magento-cache-clean).

```bash
mage watch
```

It uses the cache-clean of the project, `vendor/bin/cache-clean.js`, run with node in the [environment](../environments.md), so inside the container with Warden and DDEV. Without it, it falls back to a global one:

* **Local and Valet:** `cache-clean.js` in your `PATH`, from `composer global require mage-os/magento-cache-clean`.
* **Warden:** the global composer folder of the `php-fpm` container.
* **DDEV:** none, add it to the project.

Add it to the project with `mage add mage-os/magento-cache-clean --dev`.
