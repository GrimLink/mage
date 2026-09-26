# Mage v3 rebuild plan

Agreed on 2026-09-26. This is the reference for the rebuild, so settled decisions are not revisited without reason.

## Goal

A cleaner, extensible base for mage. Tool and environment state lives in small, separate files, the script finds the Magento root on its own, and the build produces the single `mage` file as before. The alias commands are ported after this base is done.

## Workflow

* Work happens on `feature/rebuild`. The current `mage` on main stays in place until the rebuild reaches parity, then it is released as 3.0.0.
* `src_old/` is the reference for the old code. It is deleted once `create` and `nuke` are ported.
* Everything stays compatible with bash 3.2, the version macOS ships with. So no associative arrays, `${var,,}` or `mapfile`.

## Layout

```
src/
  mage.sh          entrypoint: header, source lines, dispatch
  core/
    output.sh      colors (respects NO_COLOR), mage_info, mage_warn, mage_error
    config.sh      MAGE_* defaults, then sources ~/.config/mage/config
    tools.sh       generic CLI vars (php, composer, node, open, get, lazy magerun)
    env.sh         environment registry: detect loop, MAGE_ENV, env_call <hook>
    root.sh        Magento root detection, path argument resolving, cd
    helpers.sh     confirm, download, templates, case conversion
  env/
    local.sh       defaults
    warden.sh
    valet.sh
  commands/
    create.sh
    setup.sh
    nuke.sh
    meta.sh        help, version, self-update
  build.sh
tests/             bats suite
```

## Environments

* Each `env/<name>.sh` defines `env_<name>_detect` (returns 0 or 1) and `env_<name>_apply` (overrides the CLI vars such as `MAGENTO_CLI`, `COMPOSER_CLI`, `PURGE_CLI`). It can add hooks like `env_<name>_setup` and `env_<name>_nuke`.
* `local.sh` sets the defaults. The first env that matches wins, and its name ends up in `MAGE_ENV`.
* Priority: warden, then valet, then local. Valet is an environment, not a separate tool flag.
* Commands call hooks through `env_call` instead of checking env flags themselves.
* Warden is detected by `WARDEN_ENV_NAME` in `.env`, but only when `$PWD` is outside the container (the old code wrongly checked `$PATH`).
* Generic tools (php, composer, node, magerun, open, get) stay global vars that an env may override. Magerun is detected on first use, since the check is slow.
* DDEV is the next env to add. Others only on request.

## Magento root detection

* The root is found by walking up from `$PWD` until a folder contains both `bin/magento` and `app/etc/di.xml`. `app/etc/env.php` is not used, as it only exists after setup.
* In a nested folder, mage changes to the root automatically and prints a notice. Relative path arguments are resolved before that change.
* Outside a Magento project, only `help`, `version`, `self-update` and `create` work. Other commands abort, as before.
* `nuke` always shows the resolved root and requires typing the folder name to confirm.

## Behaviour

* Unknown commands pass through to `bin/magento`, until the aliases are ported.
* `set -o pipefail`, but not `set -e`, as that breaks interactive flows and passthrough exit codes.
* Errors go to stderr.

## Config

* Defaults live in the script as `MAGE_*` vars, for example the admin password, database credentials, store config (EUR, NL) and the default composer packages.
* `~/.config/mage/config` is sourced as shell after the defaults, so it can override any of them, arrays included.

## Commands in the first scope

### `create <name> [--edition=] [--version=] [--env=] [-y]`

* Prompts for any value not passed as a flag.
* The env prompt defaults to what is installed (warden, then valet, then local).
* Runs install, then `setup`, then adds the `.gitignore`.
* Refuses when `<name>` already exists.
* Fixes the old Warden flow, which changed into the project folder before it existed.
* The old extras (BFCache patches, Hyvä, sample data) come back as optional steps once those commands are ported.

### `setup [name]`

* Runs the Magento install in an existing checkout, so a project can be reinstalled.
* The env hook provides hosts and database settings.
* `install` is no longer a public command, `create` is the entry point.

### `nuke [--keep-files]`

* Reads the database name, credentials and OpenSearch prefix from `app/etc/env.php`, falling back to the folder name.
* Runs the env hook (Valet unsecures and unlinks its stores, Warden runs `env down -v`).
* Drops the database for local and Valet, and clears the OpenSearch indices.
* Removes the project folder, unless `--keep-files` is passed.

### `help`, `version`, `self-update`

Kept as they are.

## Build

* `src/build.sh` recursively inlines every `source` line from `src/mage.sh` into `./mage`. The build order is therefore defined once, in the entrypoint.
* `src/mage.sh` also runs unbuilt during development, so a rebuild is not needed for every change.
* The version comes from the first `## [x.y.z]` heading in `CHANGELOG.md`.
* The output is checked with `bash -n`, and with `shellcheck` when it is installed.

## Tests

A minimal bats suite covering root detection, env selection (with a fake `.env` and stub binaries on `PATH`) and the build output.

## Later

* Aliases and the remaining old commands.
* DDEV environment.
* The `create` extras (BFCache, Hyvä, sample data).
