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
Give an option with a value as one argument, such as `--report=summary`, as `--report summary` takes `summary` as a path.
The exit code is that of phpcs, so it also works in a script.

## Installation

Hyvä advises against adding the coding standard to the project, as it shares dependencies with Magento, which easily conflict.
So the first run installs it once, stand-alone, in `~/.config/mage/hyva-coding-standard`, and `mage self-update` updates it.

It runs with the `php` and `composer` of your machine, also with Warden and DDEV.
The sniffs read the PHP version of the project from its `composer.json`.

## Docker

Without PHP on your machine, run the coding standard in docker instead, with the [docker wrappers of Hyvä](https://github.com/hyva-themes/hyva-coding-standard#usage-with-docker-no-local-php-required).
It is one container next to every project, whatever its environment.

1. Clone the coding standard, and put its wrappers in your `PATH`:

   ```bash
   git clone https://github.com/hyva-themes/hyva-coding-standard.git ~/hyva-coding-standard
   ln -s ~/hyva-coding-standard/bin/phpcs-docker ~/.local/bin/phpcs-docker
   ln -s ~/hyva-coding-standard/bin/phpcbf-docker ~/.local/bin/phpcbf-docker
   ```

2. Point mage at them in the [configuration](../config.md):

   ```bash
   # ~/.config/mage/config
   MAGE_LINT_PHPCS="phpcs-docker"
   MAGE_LINT_PHPCBF="phpcbf-docker"
   ```

Mage then runs those instead, and installs nothing.
The first run builds the image, and a `git pull` in `~/hyva-coding-standard` updates it, `mage self-update` does not.
The wrapper only mounts the current folder, and mage runs from the Magento root, so the paths to lint have to be in the project.
For a path outside it, set `HYVA_PHPCS_MOUNT` to a folder above both.

The settings take any command, such as the `phpcs` of a coding standard you installed yourself, like `~/hyva-coding-standard/vendor/bin/phpcs`.
