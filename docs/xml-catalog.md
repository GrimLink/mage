# XML catalog

Magento refers to the schemas of its XML files by URN, such as `urn:magento:framework:ObjectManager/etc/config.xsd`.
An editor needs a catalog that maps each URN to its `.xsd` file, for validation and completion.

`mage create` generates one at `.vscode/catalog.xml`, in the [OASIS XML catalog](https://www.oasis-open.org/committees/entity/spec.html) format.
This format is read by the XML language server [LemMinX](https://github.com/eclipse-lemminx/lemminx), which VS Code (with the XML extension of Red Hat) and Zed (with the XML extension) use.
The `.gitignore` mage adds already ignores the `.vscode` folder.
Mage does not change your editor settings, point your editor to the catalog yourself, see below.

## Generating it

For an existing project, or after adding modules with their own schemas, generate it again:

```bash
mkdir -p .vscode
mage dev:urn-catalog:generate --ide=vscode .vscode/catalog.xml
```

The folder must exist, Magento does not create it.
Despite the name, `--ide=vscode` gives the generic format.

Magento writes each schema path as `../<path from the root>`, so the catalog only works one folder below the root.
Any other folder of the root works too, but a path such as `dev/schemas/catalog.xml` gives broken paths.

## VS Code

Install the [XML extension](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-xml) of Red Hat, and add to your settings:

```json
{
  "xml.catalogs": [".vscode/catalog.xml"]
}
```

## Zed

Enable the `xml` extension, and add to your settings:

```json
{
  "lsp": {
    "lemminx": {
      "settings": {
        "xml": {
          "catalogs": [".vscode/catalog.xml"]
        }
      }
    }
  }
}
```

## PhpStorm

PhpStorm uses its own format, which it reads from `.idea/misc.xml`:

```bash
mage dev:urn-catalog:generate .idea/misc.xml
```
