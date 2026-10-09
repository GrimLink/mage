# mage del

Remove composer packages, by name or by term.
`mage remove` does the same.

```bash
mage del vendor/package
mage del hyva
mage del hyva siteation -y
```

## By name

A first argument with a slash is a package name, and everything is passed as is to `composer remove`.

## By term

Otherwise each argument is a term.
Mage lists every direct dependency in `composer.json` that contains any of the terms, and asks once before removing them.

- Terms match as plain text and case-insensitive, so `hyva` matches `hyva-themes/magento2-default-theme` and `vendor/magento2-hyva-compat`.
- Only packages match, never platform entries such as `php` or `ext-*`.
- Packages in `require-dev` are removed with `--dev`.
- `-y` or `--yes` removes them without asking.

This requires [jq](https://jqlang.org/).
