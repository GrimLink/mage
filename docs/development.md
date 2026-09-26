# Development

The `mage` script in the root of the repository is built, never edit it directly. The source lives in `src`, the design decisions in the [rebuild plan](rebuild-plan.md).

## Layout

```
src/
  mage.sh          entrypoint: sources everything, dispatches the command
  build.sh         builds the mage script
  core/
    output.sh      colors, mage_info, mage_notice, mage_warn, mage_error, mage_check
    config.sh      MAGE_* defaults, then sources ~/.config/mage/config
    tools.sh       the commands mage runs, such as MAGENTO_CLI and COMPOSER_CLI
    env.sh         environment detection and hooks
    root.sh        Magento root detection
    helpers.sh     questions, env.php reader, downloads, composer helpers
    handlers.sh    the handler registry shared by add, clean, set and show
    templates.sh   template sync and copy
  env/             one file per environment
  commands/        one file per command
    add/           one file per add handler
    clean/         one file per clean option
    set/           one file per set option
    show/          one file per show option
templates/         files for generated code and bundled composer fragments
tests/             bats tests
```

## Running unbuilt

`src/mage.sh` runs as is, so a change needs no build while developing. It then uses the `templates` folder of the repository. An alias helps:

```bash
alias mage-dev="$HOME/path/to/mage/src/mage.sh"
```

## Building

```bash
src/build.sh          # writes ./mage
src/build.sh /tmp/x   # writes elsewhere
```

The build inlines every `source "${MAGE_SRC}/..."` line of `src/mage.sh`, recursively, so the order of those lines is the order of the script. It takes the version from the first released `## [x.y.z]` heading in `CHANGELOG.md`, and checks the result with `bash -n`. When that fails, the existing `mage` is left untouched.

## Tests

The tests use [bats](https://github.com/bats-core/bats-core):

```bash
brew install bats-core
bats tests
```

They source `src/mage.sh` without running it, and replace the commands mage would run with `echo`, such as `COMPOSER_CLI="echo composer"`, to check what would run.

## CI

On every push and pull request to main, a GitHub Action checks the built script with [ShellCheck](https://www.shellcheck.net/), using `.shellcheckrc`, and runs the tests on Ubuntu and on macOS with its bash 3.2.

## Conventions

* Stay compatible with bash 3.2: no associative arrays, `${var,,}` or `mapfile`.
* Command functions are named `mage_cmd_<name>`.
* Errors go to stderr through `mage_error`, notices through `mage_notice`.
* The `*_CLI` variables hold a command with its arguments, and are used unquoted on purpose.

## Adding a command

1. Add `src/commands/<name>.sh` with a `mage_cmd_<name>` function.
2. Source it in `src/mage.sh`, and add it to the `case` in `mage_main`.
3. When it works outside a Magento project, add it to `MAGE_ROOTLESS_COMMANDS`.
4. Add it to `mage_cmd_help` in `src/commands/meta.sh`, and document it in `docs/commands`.

## Adding an add handler, or a clean, set or show option

All four use the handler registry of `src/core/handlers.sh`. For `mage add example`:

```bash
# src/commands/add/example.sh
MAGE_ADD_HANDLERS+=("example|What it adds, shown in 'mage add help'")

function mage_add_example() {
  # the arguments after 'example' are in "$@"
}
```

Dashes in the name become underscores in the function, so `sample-files` is `mage_clean_sample_files`. Source the file in `src/mage.sh`, after its command.

## Adding an environment

1. Add `src/env/<name>.sh` with `env_<name>_available` (the tool is installed) and `env_<name>_detect` (the current folder uses it).
2. Add `env_<name>_apply` to set the `*_CLI` and `MAGE_DB_*` variables it needs.
3. Add the hooks that differ from local: `create_project`, `setup_prepare`, `setup_finish`, `clean_redis`, `add_store`, `open_mail`, `watch_cli` and `nuke`. A hook it does not define falls back to the local one.
4. Add the name to `MAGE_ENVS` in `src/core/env.sh`, in order of priority, and source the file in `src/mage.sh`.
