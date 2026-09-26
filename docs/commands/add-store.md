# mage add store

Create a store view with its own domain.

```bash
mage add store luma               # luma.<your domain>, such as luma.my-shop.test
mage add store b2b.example.test   # a full domain
```

Without an argument it asks for the prefix or domain.

## Steps

1. Derives the store code from the first part of the domain, dashes become underscores. A code must start with a letter and hold letters, numbers and underscores.
2. Creates the store view in the default store group of the default website, unless the code exists.
3. Sets its base urls, with the protocol of the main store.
4. Makes the domain reachable, depending on the [environment](../environments.md).
5. Reindexes the design config grid and flushes the cache.

## Environments

* **Valet:** adds the site to `.valet-env.php` with its store code, then links and secures it. The site name is the domain without the Valet tld, so `luma.my-shop.test` becomes the site `luma.my-shop`.
* **Warden:** signs the certificate, and tells you to route the domain in `.warden/warden-env.yml` and map it in `app/etc/stores.php`, see [multiple domains](https://docs.warden.dev/configuration/multipledomains.html).
* **DDEV:** tells you to add the domain to the `additional_fqdns` or `additional_hostnames` of `.ddev/config.yaml` and map it to the store code.
* **Local:** tells you to point the domain to the project in your web server, with the store code as `MAGE_RUN_CODE`.
