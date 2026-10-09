# mage add storeinfo

Add the [Siteation](https://siteation.dev/) StoreInfo modules.

```bash
mage add storeinfo
```

Applies the bundled [composer fragment](../composer-fragments.md) `composer-storeinfo.json`, which requires:

- `siteation/magento2-storeinfo`
- `siteation/magento2-storeinfo-menus`
- `siteation/magento2-storeinfo-usps`
- `siteation/magento2-storeinfo-payments`

Then runs `setup:upgrade`.
The package list lives in the fragment, so it is updated with `mage self-update`.
