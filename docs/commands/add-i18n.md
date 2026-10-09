# mage add i18n

Collect the translatable phrases of a module or theme into `i18n/en_US.csv`.

```bash
cd app/code/Vendor/Module && mage add i18n
mage add i18n app/code/Vendor/Module
```

The path defaults to the folder you run mage in, and a relative path is resolved from there too.
When the folder has no `registration.php`, it asks before continuing.

It runs `bin/magento i18n:collect-phrases`, quotes the lines Magento writes without quotes, and sorts them.
An existing `i18n/en_US.csv` is replaced.
