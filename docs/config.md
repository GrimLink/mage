# Configuration

Mage runs with defaults that suit most projects. To change them, create the file `~/.config/mage/config`, where `~` is your home folder (`$HOME`). This is the same on macOS and Linux, mage does not use `~/Library` on macOS. When `XDG_CONFIG_HOME` is set, the file is `$XDG_CONFIG_HOME/mage/config` instead.

The file is plain bash, sourced after the defaults. So set only what you want to change, and use the same syntax as below, arrays included.

```bash
# ~/.config/mage/config
MAGE_EDITION="community"
MAGE_ADMIN_PASS="my_own_password1"
MAGE_DB_PASS=""

MAGE_PACKAGES+=(
  vendor/my-default-module
)

MAGE_VAR_HYVA_PROJECT="acme"
```

## Settings

### Admin user

Used by `mage create` and `mage setup` to create the admin user.

| Setting | Default |
|---|---|
| `MAGE_ADMIN_USER` | Your git first name, in lowercase |
| `MAGE_ADMIN_FIRSTNAME` | Your git first name |
| `MAGE_ADMIN_LASTNAME` | `admin` |
| `MAGE_ADMIN_EMAIL` | Your git email |
| `MAGE_ADMIN_PASS` | `magento_123$` |

### New projects

| Setting | Default | Used for |
|---|---|---|
| `MAGE_EDITION` | `mage-os` | The edition `mage create` suggests: `mage-os`, `community` or `enterprise` |
| `MAGE_DOMAIN` | `test` | Stores are served as `https://<project>.<MAGE_DOMAIN>/` |
| `MAGE_PACKAGES` | See below | Packages `mage create` requires in every new project |
| `MAGE_DEV_PACKAGES` | `avstudnitz/scopehint2`, `spatie/ray` | Dev packages `mage create` requires in every new project |
| `MAGE_STORE_CONFIG` | See below | Store config `mage setup` sets after the install |

`MAGE_PACKAGES` defaults to `cweagans/composer-patches`, `yireo/magento2-theme-commands` (used to switch themes, see [`mage add hyva`](commands/add-hyva.md)), `swissup/module-ignition` and `community-engineering/language-nl_nl`. Set it to `()` to add none.

`MAGE_STORE_CONFIG` holds one `path value` entry per config value. An entry without a value sets it empty. The defaults use the Euro (with Pounds allowed), the Netherlands as the default country with the European countries allowed, turn off the admin usage tracking and forced password changes, keep the admin session for a day, and enable the canonical tags for categories and products.

```bash
MAGE_STORE_CONFIG=(
  "currency/options/base USD"
  "currency/options/default USD"
  "currency/options/allow USD"
  "general/country/default US"
)
```

### Services

The connection settings for the local environment and Valet. Warden and DDEV always use the values of their containers, see [environments](environments.md).

| Setting | Default |
|---|---|
| `MAGE_DB_HOST` | `localhost` |
| `MAGE_DB_NAME` | Empty, which uses the project folder name |
| `MAGE_DB_USER` | `root` |
| `MAGE_DB_PASS` | `root` |
| `MAGE_SEARCH_HOST` | `localhost` |
| `MAGE_SEARCH_PORT` | `9200` |
| `MAGE_REDIS_HOST` | `127.0.0.1` |

### Commands

| Setting | Default | Used for |
|---|---|---|
| `MAGE_CLEAN_ALL` | `files redis varnish` | The options `mage clean` and `mage purge` run, in order |
| `MAGE_OUTDATED_IGNORE` | `symfony/finder`, `symfony/process` | Packages `mage outdated` leaves out, Magento pins these |

### Placeholders in json files

A json file for `mage add` can hold `{{NAME}}` placeholders, which mage asks for. Set `MAGE_VAR_<NAME>` to give an answer as default, then an empty answer uses it. See [composer fragments](composer-fragments.md).

```bash
MAGE_VAR_HYVA_PROJECT="acme"
MAGE_VAR_HYVA_LICENSE_KEY="..."
```

Mind that the config is a plain file, keep secrets out of it when others can read it.

## Other files in the config folder

* `templates/`: the templates for new themes, modules and the bundled json files, see [templates](templates.md).
