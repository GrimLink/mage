# Mage

Mage is a simple helper
on top of the base options that Magento2 has with `bin/magento`

## Installation

Download mage via;

```bash
curl -O https://raw.githubusercontent.com/GrimLink/mage/master/mage
```

_Or via wget_

Add mage to your bin folder and make it executable.

```bash
chmod -x mage
```

## Commands

| CMD     | Description                          |
| ------- | ------------------------------------ |
| help    | Show all options                     |
| info    | Show base store info                 |
| open    | Open store in browser                |
| install | Install Magento                      |
| key     | Create auth.json in root of project  |
| config  | Set configs for dev env              |
| reindex | Run indexer:reindex                  |
| admin   | Create new admin                     |
| run     | Run magerun2 (requires n98-magerun2) |

Any other command will run the same as `bin/magento`