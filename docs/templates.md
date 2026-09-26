# Templates

The files mage generates come from the `templates` folder of this repository:

| Template                  | Used by                                                                             |
| ------------------------- | ----------------------------------------------------------------------------------- |
| `theme/`                  | [`mage add theme`](commands/add-theme.md)                                           |
| `module/`                 | [`mage add module`](commands/add-module.md)                                         |
| `module-hyva/`            | [`mage add module`](commands/add-module.md), the extra files of a Hyvä module       |
| `magento.gitignore`       | [`mage setup`](commands/create.md#mage-setup), when the project has no `.gitignore` |
| `composer-hyva.json`      | [`mage add hyva`](commands/add-hyva.md)                                             |
| `composer-hyva-dev.json`  | [`mage add hyva --dev`](commands/add-hyva.md)                                       |
| `composer-storeinfo.json` | [`mage add storeinfo`](commands/add-storeinfo.md)                                   |

## Sync

The first command that needs a template downloads them to `~/.config/mage/templates`.
After that they are only updated by `mage self-update`, so mage works offline and never fetches templates on a normal command.
A failed update keeps the previous templates.

Running mage unbuilt, from `src/mage.sh`, uses the `templates` folder of the repository directly, see [development](development.md).

## Placeholders

A template file holds `{{NAME}}` placeholders, which are replaced when copied, such as `{{VENDOR}}`, `{{MODULE}}` and `{{PARENT}}`.
The pages of the commands list which ones they fill.

The `composer-*.json` files are [composer fragments](composer-fragments.md), their placeholders are asked when applied.

## Using a bundled json yourself

The bundled composer fragments can also be applied directly, or copied and changed:

```bash
mage add ~/.config/mage/templates/composer-hyva.json
```
