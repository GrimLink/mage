# mage open

Open a store view or the admin in your browser.

```bash
mage open         # the default store view
mage open luma    # a store view by its code
mage open admin   # the admin
```

The url comes from Magento itself, in one call, so it matches what Magento serves: a base url set on the store view or its website, and for the admin a custom admin path or admin url. A store view is found by its exact code, an unknown code lists the codes there are.

The url is always shown, and opened with `open` on macOS or `xdg-open` on Linux when that is available, so over ssh you still get the url.
