# mage upd

Update composer packages, by name or by term.
`mage update` does the same.

```bash
mage upd
mage upd vendor/package -W
mage upd hyva -W
```

## Everything or by name

Without arguments, with a first argument that has a slash, or that is an option, everything is passed as is to `composer update`.

## By term

Otherwise each argument is a term, matched the same way as [`mage del`](remove.md): every direct dependency that contains any of the terms, in `require` and `require-dev`.
They are listed and updated in one `composer update` run.
Options among the terms, such as `-W`, go to composer.

It does not ask first, as an update is undone with the `composer.lock` in git.

This requires [jq](https://jqlang.org/).
