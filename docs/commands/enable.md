# mage enable and mage disable

Enable or disable modules, by name or by term.

```bash
mage enable Vendor_Module
mage disable hyva
mage enable hyva checkout -y
```

## By name

A first argument with an underscore is a module name, and everything is passed as is to `bin/magento module:enable` or `module:disable`.

## By term

Otherwise each argument is a term. Mage lists the modules in `app/etc/config.php` that contain any of the terms, and asks once before changing them.

* Terms match as plain text and case-insensitive.
* `enable` only matches disabled modules, `disable` only enabled ones.
* `-y` or `--yes` changes them without asking.
* Other options, such as `--clear-static-content`, go to Magento.

Reading `config.php` needs no Magento boot, so only the change itself runs `bin/magento`.
