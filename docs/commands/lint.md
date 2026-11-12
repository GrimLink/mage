# mage lint

Check the code with the [Hyvä coding standard](https://github.com/hyva-themes/hyva-coding-standard), which extends the Magento coding standard.

```bash
mage lint app/code/Acme/Module                     # a path, relative to the current folder
mage lint vendor/hyva-themes/magento2-theme-module # a package
mage lint app/code/Acme/Module -s --report=summary # options go to phpcs
mage lint app/code/Acme/Module --fix               # fix what phpcbf can fix
```

It needs a path, and never checks the whole project, as that also holds the `vendor` folders of local packages, which take long and show nothing until done.
It checks `php`, `phtml` and `xml` files, and skips `node_modules`, but not `vendor`, so give the path of the package, not a folder that holds its dependencies.
It shows its progress with a dot per file, `-q` turns that off.
The exit code is that of phpcs, so it also works in a script.

## Installation

Hyvä advises against adding the coding standard to the project, as it shares dependencies with Magento, which easily conflict.
So the first run installs it once, stand-alone, in `~/.config/mage/hyva-coding-standard`, and `mage self-update` updates it.

It runs with the `php` and `composer` of your machine, also with Warden and DDEV.
The sniffs read the PHP version of the project from its `composer.json`.
