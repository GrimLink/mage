# Mage

Mage is a simple bash helper
on top of the options that Magento2 offers with `bin/magento`.

The main focus of mage is being a shorthand and alias for `bin/magento`.
so your typing less for the same commands.

`bin/magento` already offers the option of typing all there commands
in shorter versions.

E.g.

| Full                      | Short             | mage       |
| ------------------------- | ----------------- | ---------- |
| `bin/magento cache:flush` | `bin/magento c:f` | `mage c:f` |

But next to making typing less.
mage also commes packing with a few custom functions.

[Check them out at the commands section](#commands)

## Installation

Download mage via:

```bash
wget https://raw.githubusercontent.com/GrimLink/mage/main/mage && chmod +x mage
```

or if you prefer to use Curl:

```bash
curl -O https://raw.githubusercontent.com/GrimLink/mage/main/mage && chmod +x mage
```

## Commands

| CMD              | Description                                                                 |
| ---------------- | --------------------------------------------------------------------------- |
| --help / -h      | Show all options                                                            |
| self-update      | Update mage                                                                 |
| info             | Show minimal store info (e.g. version and uri)                              |
| stores           | Show all stores _\*1_                                                       |
| open             | Open the default store, in the browser                                      |
| open admin       | Open store admin, in the browser                                            |
| open _STOREVIEW_ | Open specific storeview, in the browser _\*1_                               |
| auth             | Copy the auth.json from root                                                |
| config           | Set configs for dev env                                                     |
|                  | [`--cache`/`-c`] Disable any frontend caches                                |
|                  | [`--admin-session`/`-a`] Set admin session to a day and no password updates |
|                  | [`--disable-security`/`-s`] Disable any captcha and 2fa options             |
|                  | [`--dev-mode`/`-d`] Set all settings for local development                  |
| devclean         | Run cache-clean.js from mageTV                                              |
| purge            | Purge all static assets                                                     |
|                  | [`--redis`/`-r`] Also flush the redis cache                                 |
| new admin        | Create new admin user _\*2_                                                 |
| new customer     | Create new customer _\*1_                                                   |
| new theme        | Create new theme in app _\*2_                                               |
| new module       | Create new module in app                                                    |
| add sample       | Add sample data                                                             |
| add hyva         | Add Hyva theme                                                              |
| replace          | Removal of (optional) core modules)                                         |
| install \| i     | Run composer install or require                                             |
| remove \| rm     | Run composer remove                                                         |
| run              | Run magerun2 _\*1_                                                          |

Any other command will run the same as `bin/magento`

> _\*1_ requires [n98-magerun2](https://github.com/netz98/n98-magerun2)
>
> _\*2_ add the flag `--yes` or `-y`, for using on yes all questions

## Supported platforms/environments

This scrips is tested in theses following platforms/environments,
and works without any extra work.

- OSX + ValetPlus
- OSX + Laravel Valet
  - Also supports scoped php (`valet isolate`) in Laravel Valet 3
- Most Linux platforms
- [Warden](https://github.com/davidalger/warden) _(thanks to [@tdgroot](https://github.com/tdgroot))_
