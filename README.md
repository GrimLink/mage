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

| CMD        | Description                                             |
| ---------- | ------------------------------------------------------- |
| help       | Show all options                                        |
| info       | Show minimal store info (e.g. version, uri's, settings) |
| open       | Open store in browser (optional pass storeview)         |
| open admin | Open store admin in browser                             |
| install    | Run Magento install steps _(#1)_                        |
| key        | Create an auth.json in the root                         |
| config     | Set configs for dev env                                 |
| purge      | Purge all static assets                                 |
| admin      | Create new admin user _(#2)_                            |
| run        | Run magerun2 (requires n98-magerun2)                    |

Any other command will run the same as `bin/magento`

_#1_ For the best experiences try [create-project](https://github.com/GrimLink/create-project).
To easily install Magento or any other project.

_#2_ Add the flag `--yes` or `-y` for using yes to all questions.
