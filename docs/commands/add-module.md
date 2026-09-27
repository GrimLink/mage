# mage add module

Create a new module.

```bash
mage add module
mage add module Vendor/MyModule --hyva
mage add module Vendor/MyModule --no-hyva
```

| Option        | Does                                   |
| ------------- | -------------------------------------- |
| `Vendor/Name` | The vendor and name of the module      |
| `--hyva`      | Create a Hyvä module                   |
| `--no-hyva`   | Create a module without the Hyvä files |

Anything not given is asked.
The Hyvä question defaults to yes when Hyvä is installed.
The vendor and name become the PHP namespace, so they can only hold letters and numbers.

## Where it is created

It asks whether to create the module in `package-source` as a composer package:

- **No:** `app/code/Vendor/MyModule`, where Magento loads it by its namespace.
- **Yes:** `package-source/vendor/magento2-my-module`, which is required as `@dev` right away.

An existing folder is never overwritten.

## Files

From the [template](../templates.md) `module`: `registration.php`, `etc/module.xml`, `composer.json` (named `vendor/magento2-my-module`), `README.md`, `CHANGELOG.md`, `SECURITY.md` (with `security@example.com` to replace), `.editorconfig` and `.gitignore`.
The module sequences `Magento_Theme`.

A Hyvä module sequences `Hyva_Theme` instead, and gets the files of the template `module-hyva`: an observer with its `etc/frontend/events.xml` that registers the module in the Hyvä tailwind config, and the tailwind sources in `view/frontend/tailwind`.

Run `mage setup:upgrade` afterwards to enable the module.
