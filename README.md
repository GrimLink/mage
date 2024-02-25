# Mage

Mage is a simple bash helper
on top of the options that Magento2 offers with `bin/magento`.

The main focus of mage is being a shorthand and alias for `bin/magento`.
so your typing less for the same commands.

`bin/magento` already offers the option of typing all there commands
in shorter versions, but mage makes it even shorter.

E.g.

| Full                      | Short             | mage       |
| ------------------------- | ----------------- | ---------- |
| `bin/magento cache:flush` | `bin/magento c:f` | `mage c:f` |

Next to making you type less.
mage also commes packing with a few custom functions that work as aliases.

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

You can view all of the mage custom options by using `mage help`.

<details><summary>View all commands from <code>mage help</code></summary>

```sh
- info (Show base config for store)
- self-update (Update mage)
- stores (Show all stores)
- open (Open store in browser)
- watch (Run cache-clean.js from mageTV)
- purge (Purge all static assets)
- new admin (Create new admin user)
- new customer (Create new customer)
- new theme (Create new theme)
- new module (Create new module)
- new i18n (Create new translations)
- add sample (Add sample data)
- add hyva (Add Hyva Theme)
- add checkout (Add Hyva Checkout)
- set config (Set Magento Configs)
- set hyva (Set hyva default theme)
- set theme (Set theme)
- composer (Run composer, Usefull for valet php)
- install | i (Run composer install or require)
- update | up (Run composer update)
- remove | rm (Run composer remove)
- build (Run setup:static-content:deploy with common defaults)
- run (Run magerun2)

Anything else will run bin/magento
```

> `mage run` is an aliases for [n98-magerun2] and so requires it

> Any command with Hyvä in its name requires a [Hyvä license] or gitlab access

> `set theme` or `set hyva` is an aliases for [Yireo_ThemeCommands] and so requires it

</details>

Down here are a few very helpfull once that we want to highlight.

### mage open

Inspired by `valet open` it will open your default store,
but `mage open` also comes with a few extra tricks, it can even open a store based on the storeview name.

so if you use;

```sh
mage open b2b
```

it will open the b2b store url.

Lastly there one extra trick, it can also open de admin page by using;

```sh
mage open admin
```

## Supported platforms/environments

This scrips is tested in theses following platforms/environments,
and works without any extra work.

- OSX + Laravel Valet
  - Also supports scoped php (`valet isolate`) in Laravel Valet 3
- Most Linux platforms
- [Warden](https://github.com/davidalger/warden) _(thanks to [@tdgroot](https://github.com/tdgroot))_

[n98-magerun2]: https://github.com/netz98/n98-magerun2
[Hyvä license]: https://www.hyva.io/hyva-themes-license.html
[Yireo_ThemeCommands]: https://github.com/yireo/Yireo_ThemeCommands
