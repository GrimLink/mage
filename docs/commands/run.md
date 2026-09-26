# mage run

Run [n98-magerun2](https://github.com/netz98/n98-magerun2), with all arguments as is.

```bash
mage run sys:info
mage run db:console
```

Mage uses `magerun2` or `n98-magerun2` from your machine, whichever works first, and inside the container with Warden. When neither is installed, or it does not work with your PHP version, it stops with an error.

With DDEV it uses the magerun on your machine, which cannot reach the DDEV database.
