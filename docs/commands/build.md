# mage build

Build themes with their npm scripts, or watch one.

```bash
mage build                  # every theme
mage build my-theme         # what matches my-theme
mage build my-theme --watch # watch it
```

Mage looks for `package.json` files in `app/design` and `package-source`, such as the `web/tailwind/package.json` of a Hyvä theme, that have the npm script to run.
Folders named `node_modules` are skipped.

- **Without a target** it runs the `build` script of every theme.
  A theme is a package with a `theme.xml` in its root, so modules are left out.
- **A target** matches part of the path, case-insensitive, so it can also pick a module, such as `mage build my-module`.
  Everything that matches is built.
- **`--watch` or `-w`** runs the `watch` script instead, which keeps running.
  It needs a target, and when the target matches more than one package, it asks which.

When `node_modules` is missing it first runs `npm ci`, or `npm install` without a `package-lock.json`.
npm runs in the [environment](../environments.md), so inside the container with Warden and DDEV.

The script names are `MAGE_BUILD_SCRIPT` and `MAGE_WATCH_SCRIPT` in the [configuration](../config.md), `build` and `watch` by default, for a theme that uses another name, such as `serve`.

Luma themes have no npm build, for those [`mage watch`](watch.md) cleans the caches a change affects.

## The Hyvä theme in vendor

`mage build hyva` builds the Hyvä default theme in `vendor`, or the CSP one when that is installed, and `mage build hyva --watch` watches it.
It is not listed in `mage help`, as a theme in `vendor` is normally not built in a project.
