# mage test

Run the test actions of the project, listed in the `mage.config.json` in its root.

```bash
mage test
```

Each action is a shell command, run in order from the root of the project, where `mage` is mage itself:

```json
{
  "test": [
    "mage lint app/code/Acme/Module",
    "composer validate app/code/Acme/Module/composer.json",
    "vendor/bin/phpunit -c dev/tests/unit/phpunit.xml.dist app/code/Acme"
  ]
}
```

They run on your machine, also with Warden and DDEV, so use `mage` or the command of the environment for what has to run in the container.

## Blocked actions

Tests check, they never change the project, so `mage test` refuses to run when an action removes, moves or writes files.
It then lists those actions, and runs none of them.
It blocks:

- The commands `rm`, `rmdir`, `mv`, `cp`, `dd`, `truncate`, `shred`, `unlink`, `ln`, `chmod`, `chown`, `chgrp`, `tee`, `rsync`, `mkdir` and `touch`, also after `|`, `xargs`, `-exec` or `sudo`, and with a path such as `/bin/rm`.
- `find -delete`, and editing in place with `sed -i` or `perl -i`.
- The git commands that change the working tree: `clean`, `reset`, `checkout`, `restore`, `rm`, `mv`, `stash` and `switch`.
- `mage nuke` and `mage destroy`.
- A redirect to a file with `>` or `>>`, while one to `/dev/null`, such as `> /dev/null 2>&1`, is fine.

This guards against mistakes, it is no sandbox.
A command can still change files itself, such as a composer or npm script, and a shell can always get around a list.
So treat a `mage.config.json` like any script of a project, and only run `mage test` in projects you trust.

## Results

All actions run, also after one fails, and it ends with a list of those that failed.
It exits with 1 when any of them failed, so it also works in a script.

## Creating the mage.config.json

Without a `mage.config.json`, it offers to create one from the [template](../templates.md), which runs [`mage lint`](lint.md) on `app/code`.
With `-y` or `MAGE_YES=1` it creates it without asking.
Its `docs` key links to this page, mage does not read it.
The [gitignore template](../templates.md) ignores it, so each developer keeps their own, and a clone never brings actions along that run on your machine.

For working on the Hyvä theme module and default theme, the template `mage-hyva.config.json` is a sample.
It validates their `composer.json`, checks the PHP syntax and lints both.
Copy it from `~/.config/mage/templates` to the root of the project as `mage.config.json`.
