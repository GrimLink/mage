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
So the first run installs it stand-alone, where it runs:

| Environment   | Installed in                          | Runs with                                 |
| ------------- | ------------------------------------- | ----------------------------------------- |
| Local, Valet  | `~/.config/mage/hyva-coding-standard` | The `php` and `composer` of your machine  |
| Warden, DDEV  | `hyva-coding-standard` in the project | The `php` and `composer` of the container |

The container only sees the project, so with Warden and DDEV the paths to lint have to be in the project.
The [gitignore template](../templates.md) ignores the `hyva-coding-standard` folder.
Exclude it in your IDE as well, so it is not indexed.
It also lets PhpStorm use the coding standard with the PHP interpreter of the container, see the [Hyvä instructions](https://github.com/hyva-themes/hyva-coding-standard#with-php-in-docker-eg-warden).

`mage self-update` updates the one on your machine.
The one in a project stays at its version, as part of the project, update it yourself with the composer of the container:

```bash
warden env exec php-fpm composer update -d hyva-coding-standard
ddev exec -d /var/www/html/hyva-coding-standard composer update
```

The sniffs read the PHP version of the project from its `composer.json`.
