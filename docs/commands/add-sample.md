# mage add sample

Add sample data, one set at a time.

```bash
mage add sample           # asks which set
mage add sample magento   # the Luma sample data of Magento
mage add sample hyva      # the Koti sample data of Hyvä
```

Without a set it asks, defaulting to `hyva` when Hyvä is installed, otherwise `magento`.
Further arguments go to the deploy command of the set.
Afterwards it reindexes and cleans the cache.

## magento

Runs `bin/magento sampledata:deploy`, which adds the sample data packages of the installed version through composer, then `setup:upgrade`.
This works for every edition, and inside a Warden or DDEV container.
Magento Open Source and Adobe Commerce need your marketplace keys in the composer auth.

The sample data adds the Luma styles to the head of every page, so mage clears `design/head/includes` again.
When Hyvä is installed, it switches back to `Hyva/default` where possible, see [`mage add hyva`](add-hyva.md).

## hyva

Runs `bin/magento hyva:sampledata:deploy`, then `setup:upgrade`, see the [Hyvä sample data docs](https://docs.hyva.io/hyva-themes/getting-started/sample-data.html).
It needs the Hyvä Theme, `Hyva_Theme` 1.4.7 or later.

The Koti packages come with a Hyvä license, through the `https://hyva-themes.repo.packagist.com/` repository in `composer.json`.
Without that repository, such as for Hyvä from the Hyvä GitLab ([`mage add hyva --dev`](add-hyva.md)) or from `package-source`, mage first adds the Koti repositories of the GitLab from the bundled `composer-hyva-sample-dev.json`, read over ssh.

With the Luma sample data installed, it asks whether to replace it, which removes all products, orders and customers, or to keep it, which gives Koti its own website.
Pass `--keep-luma` or `--replace-luma` to skip the question, or `--reinstall` to reset Koti.
