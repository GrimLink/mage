# mage open

Open a store view, the admin or the mail catcher in your browser.

```bash
mage open         # the default store view
mage open luma    # a store view by its code
mage open admin   # the admin
mage open mail    # the mail catcher
```

The url comes from Magento itself, in one call, so it matches what Magento serves: a base url set on the store view or its website, and for the admin a custom admin path or admin url.
A store view is found by its exact code, an unknown code lists the codes there are.

`mail` opens the mail catcher of the [environment](../environments.md): Mailpit at `https://webmail.warden.test/` with Warden, `ddev launch -m` with DDEV, and `MAGE_MAIL_URL` otherwise, `http://localhost:8025` by default.

> [!note]
> If a store view with the code `admin` or `mail` is used it can not be opened by `mage open`.
So avoid using that for the code.

The url is always shown, and opened with `open` on macOS or `xdg-open` on Linux when that is available, so over ssh you still get the url.
