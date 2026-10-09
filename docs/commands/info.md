# mage info

Show the main facts of the project.

```bash
mage info
```

It shows the Magento product and version, with the Hyvä version when installed, the mode, whether maintenance is on, the base and admin url, the database, the search engine, the Redis the caches and sessions use with their databases and cache prefix, the PHP and Node version, and the number of enabled modules outside Magento itself.

Everything comes from Magento in one boot, so the PHP version is the one that runs Magento, inside the container with Warden and DDEV.
The admin url counts a custom admin path and url, the same as [`mage open admin`](open.md).
From 50 modules the count turns yellow, from 100 red, as every module adds to each request.
