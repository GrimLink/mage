# mage add theme

Create a child theme of a given parent theme.

```bash
mage add theme
mage add theme Vendor/MyTheme --parent=Hyva/default
mage add theme Vendor/Admin --admin
```

| Option           | Does                                              |
| ---------------- | ------------------------------------------------- |
| `Vendor/Name`    | The vendor and name of the theme                  |
| `--parent=THEME` | The parent theme                                  |
| `--admin`        | Create an admin theme instead of a frontend theme |

Anything not given is asked.
The name can be answered as `Vendor/Name` at once, or the vendor is asked separately.
The parent defaults to `Hyva/default` when Hyvä is installed, otherwise `Magento/luma`, or `Magento/backend` for an admin theme.

## Where it is created

It asks whether to create the theme in `package-source` as a composer package:

- **No:** `app/design/<area>/Vendor/my-theme`.
- **Yes:** `package-source/vendor/magento2-theme-my-theme`, which is required as `@dev` right away.

The theme path uses the name in kebab case, so `Vendor/MyTheme` becomes `Vendor/my-theme`.
An existing folder is never overwritten.

## Files

From the [template](../templates.md) `theme`: `theme.xml`, `registration.php`, `composer.json` (named `vendor/magento2-theme-my-theme`), `README.md`, `CHANGELOG.md`, `SECURITY.md` (with `security@example.com` to replace), `.editorconfig` and `.gitignore`.

A child theme of a Hyvä theme also gets a copy of the `web/tailwind` folder of the Hyvä default theme, without `node_modules`, to build its own styles.

Run `mage setup:upgrade` afterwards to register the theme.
