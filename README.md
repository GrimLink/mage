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
curl -O https://raw.githubusercontent.com/GrimLink/mage/master/mage && chmod +x mage
```

_Or download it via wget_

## Commands

| CMD        | Description                                     |
| ---------- | ----------------------------------------------- |
| help       | Show all options                                |
| info       | Show minimal store info (e.g. version and uri)  |
| open       | Open store in browser (optional pass storeview) |
| open admin | Open store admin in browser                     |
| auth       | Copy the auth.json from root                    |
| config     | Set configs for dev env                         |
| purge      | Purge all static assets                         |
| new-admin  | Create new admin user _(*)_                     |
| new-theme  | Create new theme in app _(*)_                   |
| run        | Run magerun2 (requires n98-magerun2)            |

Any other command will run the same as `bin/magento`

_#_ Add the flag `--yes` or `-y` for using yes to all questions.
