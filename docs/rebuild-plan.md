# Mage v3 rebuild plan

Agreed on 2026-09-26.
This is the reference for the rebuild, so settled decisions are not revisited without reason.

## Goal

A cleaner, extensible base for mage.
Tool and environment state lives in small, separate files, the script finds the Magento root on its own, and the build produces the single `mage` file as before.
The alias commands are ported after this base is done.

## Workflow

- Work happens on `feature/rebuild`.
  The current `mage` on main stays in place until the rebuild reaches parity, then it is released as 3.0.0.
- The old source is removed, the git history of main still has it.
- Everything stays compatible with bash 3.2, the version macOS ships with.
  So no associative arrays, `${var,,}` or `mapfile`.

## Layout

```
src/
  mage.sh          entrypoint: header, source lines, dispatch
  core/
    output.sh      colors (respects NO_COLOR), mage_info, mage_warn, mage_error
    config.sh      MAGE_* defaults, then sources ~/.config/mage/config
    tools.sh       CLI vars (magento, php, composer, node, mysql, open, lazy magerun)
    env.sh         environment registry: detect loop, MAGE_ENV, env_call <hook>
    root.sh        Magento root detection, path argument resolving, cd
    helpers.sh     ask, confirm, env.php reader, download, templates
    handlers.sh    shared handler registry logic for add and clean
    templates.sh   template sync and copy with {{NAME}} replacements
    php.sh         mage_php: php code with Magento booted, shared by open, info and add store
  env/
    local.sh       fallback for every hook
    warden.sh
    ddev.sh
    valet.sh
  commands/
    create.sh
    setup.sh
    nuke.sh
    add.sh         dispatcher for mage add, git clones
    add-json.sh    composer fragments from json files
    remove.sh      del and remove
    update.sh      upd and update
    outdated.sh
    add/           one file per add handler
    clean.sh       dispatcher for mage clean
    clean/         one file per clean handler
    set.sh         dispatcher for mage set
    set/           one file per set handler
    show.sh        dispatcher for mage show
    show/          one file per show handler
    meta.sh        help, version, self-update
  build.sh
tests/             bats suite
```

## Environments

- Each `env/<name>.sh` defines `env_<name>_available` (the tool is installed), `env_<name>_detect` (the current folder uses it) and optionally `env_<name>_apply` (overrides the CLI vars such as `MAGENTO_CLI`, `COMPOSER_CLI`, `PURGE_CLI`, and the `MAGE_DB_*` settings).
- Other hooks: `create_project`, `setup_prepare`, `setup_finish`, `clean_redis`, `add_store`, `open_mail`, `watch_cli` and `nuke`.
  `env_call <hook>` runs the hook of the current env, falls back to the local one, and does nothing when neither defines it.
- The CLI defaults live in `core/tools.sh`, `local.sh` holds the local hooks.
  The first env that matches wins, and its name ends up in `MAGE_ENV`.
- Priority: warden, then ddev, then valet, then local.
  Valet is an environment, not a separate tool flag.
- Commands call hooks through `env_call` instead of checking env flags themselves.
- Warden is detected by `WARDEN_ENV_NAME` in `.env`, and only when the `warden` binary is installed.
  Inside the container it is not, so mage runs there as local (the old code wrongly checked `$PATH` for this).
- Generic tools (php, composer, node, magerun, open) stay global vars that an env may override.
  Magerun is detected on first use, since the check is slow.
- DDEV is detected by `.ddev/config.yaml`, and only when the `ddev` binary is installed.
  `mage create` sets it up with the OpenSearch and Redis add-ons and settings management off, following the DDEV Magento quickstart.
  Its stores use the `ddev.site` domain.
- Other environments only on request.

## Magento root detection

- The root is found by walking up from `$PWD` until a folder contains both `bin/magento` and `app/etc/di.xml`.
  `app/etc/env.php` is not used, as it only exists after setup.
- In a nested folder, mage changes to the root automatically and prints a notice.
- Commands that take a path resolve it with `mage_resolve_path`, relative to the root.
  The `bin/magento` fallback passes its arguments unchanged.
- `mage_main` checks `MAGE_ROOTLESS_COMMANDS` first, then runs one flat `case`.
  Every other command enters the root and detects the environment before it runs.
- Outside a Magento project, only `help`, `version`, `self-update` and `create` work.
  Other commands abort, as before.
- `nuke` always shows the resolved root and requires typing the folder name to confirm.

## Behaviour

- Unknown commands pass through to `bin/magento`, until the aliases are ported.
- Command functions are named `mage_cmd_<name>`, so they never collide with helpers.
- `set -o pipefail`, but not `set -e`, as that breaks interactive flows and passthrough exit codes.
- Errors go to stderr.

## Config

- Defaults live in the script as `MAGE_*` vars, for example the admin password, database credentials, store config (EUR, NL) and the default composer packages.
- `~/.config/mage/config` is sourced as shell after the defaults, so it can override any of them, arrays included.

## Commands in the first scope

### `create <name> [--edition=] [--version=] [--env=] [-y]`

- Prompts for any value not passed as a flag.
- The edition defaults to `MAGE_EDITION` from the config, which is `mage-os`.
- The env prompt defaults to what is installed (warden, then ddev, then valet, then local).
- Runs install, then `setup`, then adds the `.gitignore`.
- Refuses when `<name>` already exists.
- Fixes the old Warden flow, which changed into the project folder before it existed.
- The old extras (BFCache patches, Hyvä, sample data) come back as optional steps once those commands are ported.

### `setup [name]`

- Runs the Magento install in an existing checkout, so a project can be reinstalled.
- Asks for confirmation when `app/etc/env.php` exists, as it drops the database.
- The env hook provides hosts and database settings.
- Every project gets its own prefixes, all based on the database name: the OpenSearch index prefix and the Redis cache and page cache id prefixes (`<db_name>_`).
- `install` is no longer a public command, `create` is the entry point.

### `nuke [--keep-files]`

- Local and Valet read the database name and credentials from `app/etc/env.php` in their nuke hook, falling back to the folder name and the `MAGE_DB_*` settings.
  Warden and DDEV need neither, they remove the whole environment.
- The OpenSearch host, port and prefix come from `config:show catalog/search`, before the database is dropped.
- The Redis prefix, host, port and database of each cache come from `app/etc/env.php`.
  Only keys matching `zc:*:<prefix>*` are deleted, never `flushall`, so other projects on a shared Redis keep their cache.
- Runs the env hook (Valet unsecures and unlinks its stores, Warden runs `env down -v`).
- Drops the database for local and Valet, and clears the OpenSearch indices and Redis cache keys of the project only.
- Removes the project folder, unless `--keep-files` is passed.

### `add`

Resolved in this order, never mixed:

1. **Handler:** a name registered in `MAGE_ADD_HANDLERS` as `name|description`, implemented as `mage_add_<name>` (dashes become underscores) in its own file in `commands/add/`.
   The registry logic is shared with `clean`, see `core/handlers.sh`.
   It gets the remaining arguments.
   The old `new …` commands (theme, module, store, patch …) return as handlers.
2. **Json file:** anything ending in `.json`, see the composer fragments below.
3. **Git url:** anything ending in `.git` (ssh urls).
   It is cloned into `package-source/<vendor>/<name>`, using the name from its `composer.json`, and required as `<name>:dev-<branch> as <latest tag>` (a leading `v` stripped), or `<name>:@dev` without a tag.
   An existing clone with the same origin is reused.
   The `local-packages` path repository is registered when missing.
   Further arguments go to composer.
4. **Anything else:** passed as is to `composer require`, so composer handles the errors.

Without arguments it errors with its own help page, listing the composer and git forms and every registered handler.
`mage add help` shows the same page.

### Composer fragments, `add <file>.json`

- A json file with composer.json keys: `description`, `repositories`, `config`, `auth`, `require` and `require-dev`.
  The file name is free, such as `composer-hyva.json`.
  Unknown keys are skipped with a warning.
- The path is resolved from the folder mage was called in.
  There is no lookup by name, a handler like `add hyva` does more than composer and uses a bundled json itself.
  Development setups get their own file, such as `hyva-dev.json`.
- Applied in the order auth, repositories, config, then one `composer require` for `require` and one with `--dev` for `require-dev`.
- `repositories` is an object keyed by name, each value is passed as json to `composer config repositories.<name>`.
- `config` is flattened to dotted keys (`allow-plugins.vendor/name`), lists are not supported.
- `auth` follows the composer `auth.json` format and goes to the global composer auth, never to the project, as the Magento gitignore does not ignore `auth.json`.
  `http-basic` takes a username and password, other types such as `gitlab-token` a single token.
- `{{NAME}}` placeholders (uppercase, digits, underscores) are asked, with `MAGE_VAR_<NAME>` from the config as the default.
  Placeholders inside `auth` are secrets, their input is hidden.
  Answers are escaped for json.
- Requires `jq`, with a clear error when it is missing.
- Anything that is not composer, such as `setup:upgrade`, belongs to the future `import` command.
- `templates/composer-hyva.json` is the bundled example: the Hyvä license auth, the private packagist repository and the theme packages.
  It asks for `HYVA_LICENSE_KEY` and `HYVA_PROJECT`.

### `del` / `remove [PKG|TERM] [-y]`

- A name with a slash is passed as is to `composer remove`, like `add` passes to `composer require`.
- Otherwise each argument is a term.
  The direct dependencies from `composer.json` (with `jq`) that contain any term, case-insensitive and as plain text, are listed and removed after one confirmation, `-y` skips it.
  Platform entries such as `php` and `ext-*` never match.
- Matches in `require` and `require-dev` are removed in separate composer runs, the latter with `--dev`.

### `upd` / `update [PKG|TERM] [OPTIONS]`

- Without arguments, with a name with a slash, or starting with an option, everything is passed as is to `composer update`.
- Otherwise each argument is a term, matched the same way as `del` through `mage_composer_matches`, and all matches (dev included) are updated in one run.
  Options among the terms go to composer.
- No confirmation, an update is undone with the `composer.lock` in git.

### `enable` / `disable [MODULE|TERM] [-y]`

- A name with an underscore is passed as is to `module:enable` or `module:disable`.
- Otherwise the terms match, plain and case-insensitive, the modules in `app/etc/config.php` that can change (disabled for enable, enabled for disable), without booting Magento.
  Listed and confirmed once, `-y` skips it, other options go to Magento.
  Only options without a term is refused, as the empty pattern would match every module.

### `outdated [ARGS]`

- Runs `composer outdated --direct --no-dev`, ignoring the packages in `MAGE_OUTDATED_IGNORE` (default the symfony packages Magento pins).
  Further arguments go to composer.
- Writes the result as json to `composer-outdated.json` (ignored by the gitignore template), or with `--terminal` shows it instead.

### `add theme [Vendor/Name] [--parent=THEME] [--admin]`

- Asks for anything not given.
  `Vendor/Name` works as one answer, the path uses the kebab-case name (`Vendor/my-theme`).
- The parent defaults to `Hyva/default` when the Hyvä default theme is installed, otherwise `Magento/luma`, or `Magento/backend` for an admin theme.
- Creates the theme in `app/design/<area>/Vendor/my-theme`, or when chosen in `package-source/<vendor>/magento2-theme-my-theme`, named after its composer package like git clones.
  A theme in package-source is required as `@dev`.
- A Hyvä child theme gets a copy of the default theme `web/tailwind` folder, without `node_modules`.
- The files come from `templates/theme`.

### `add patch` and `add bfcache`

- One command, the input decides: a package alone creates a patch from your changes in its vendor folder (the old `new patch`), a GitHub or GitLab repository url adds all its patches (downloads `main`, merges its `patches.json`, copies its patches), and a package with a name and source adds that patch (source last, so the name can be several words).
  All run `patches-relock` and `patches-repatch`.
- Creating tracks the vendor folder with a temporary git repository and uses `git add -A` with `git diff --cached`, so new files are part of the patch.
  A second local patch of a package is numbered.
  A package that is a git repository, or a symlink from a path repository, is refused, as it is managed by the user.
- What depends on the patch tool is in `mage_patch_check_tool`, `mage_patch_register`, `mage_patch_merge` and `mage_patch_apply`, now for `cweagans/composer-patches`, so `vaimo/composer-patches` can be added as another tool.
  Edits `patches.json` with jq.
- `add bfcache` is `add patch` with the BFCache patch repository.

### `add sample [magento|hyva]`

- One set at a time, from a registry like the handlers: `MAGE_SAMPLE_SETS`, `mage_sample_<name>`, one file per set in `commands/add/sample/`. Without a set it asks, `hyva` by default when Hyvä is installed.
- `magento` uses `sampledata:deploy`, which fits the installed version and edition and works inside containers, where the old git clone did not. Then sets Hyvä as theme when installed.
- `hyva` uses `hyva:sampledata:deploy` (Koti), needs Hyvä, and asks to keep or replace Luma sample data when present.
  When `composer.json` has no repository with a `https://hyva-themes.repo.packagist.com/` url (no license, such as Hyvä from the GitLab or from package-source), it first applies `composer-hyva-sample-dev.json` with the 19 Koti repositories, generated from the GitLab group `hyva-themes/sample-data/koti`.
- Further arguments go to the deploy command. Then, for either set, it asks to clear `design/head/includes` (both add their styles there, yes by default), reindexes and cleans the cache.

### `add admin` and `add customer`

- `add admin` asks for the admin user with the `MAGE_ADMIN_*` settings as defaults (password hidden), `-y` uses them without asking, then runs `admin:user:create`.
- `add customer` runs magerun `customer:create`, Magento has no command for it, arguments go to magerun.

### `add store` and `add i18n`

- `add store [PREFIX|DOMAIN]`: a prefix becomes `<prefix>.<base domain>`, the code is the first part of the domain with dashes as underscores.
  Creates the store view in the default group with php (Magento has no command for it), sets its base urls, runs the `add_store` env hook, reindexes the design grid.
  Valet uses the site name without its tld, the old script used the full domain.
- `add i18n [PATH]`: the path is resolved from the calling folder, collects the phrases into a sorted and quoted `i18n/en_US.csv`, without the macOS only `sed -i`.
- `new gitignore` is not ported, `setup` adds the gitignore and anything after that is up to the user.

### `open [STORE|admin]`

- One php bootstrap asks Magento for the url, instead of magerun or several `config:show` calls: store view and website scope, custom admin path and admin url all count.
  A store view matches its exact code, an unknown one lists the codes.
- Always prints the url, and opens it when the open command exists.
- `open mail` goes through the `open_mail` env hook: the global Warden Mailpit, `ddev launch -m`, or `MAGE_MAIL_URL` (default Mailpit on `localhost:8025`) locally and with Valet.
- Store urls stay with Magento, not the env configs (`valet open`, Warden `.env`, `ddev describe`): those only know the primary url, not store views, website scopes or the admin path.
  A url cache is not worth it, a warm Magento boots once in about half a second.
- The old `start` (editor, git client, store and admin) is not ported.

### `watch`

- Picks the command first, then runs it: `vendor/bin/cache-clean.js` through `NODE_CLI`, so in the container with Warden and DDEV, or else the global one the `watch_cli` env hook echoes (`cache-clean.js` in the `PATH`, the global composer folder of the Warden container, none for DDEV).
  No command is an error, the status of the watcher itself is never checked.
  Arguments are ignored, the watcher is all it runs.

### `reindex`

- A shortcut: `indexer:reindex`, then `cache:clean` only when that succeeds.
  Arguments are ignored, `mage indexer:reindex` covers specific indexes.

### `log [FILE]`

- Follows `var/log/<FILE>.log` with `tail -f`, `debug` by default, the name with or without `.log`.
  A missing log lists the ones there are.
- The old `log show` is `show logs` (names and sizes), `log clear` is `clean logs` (not in `MAGE_CLEAN_ALL`).

### `info`

- One php bootstrap returns `INFO:key=value` lines, instead of about eight Magento boots and a `composer show`: product and version, Hyvä version (Composer's installed data), mode, maintenance, base and admin url (`mageAdminUrl`, shared with `open`), database, search engine, Redis (server, the databases of the caches and sessions, and the cache prefix, from `env.php`), the PHP version that runs Magento, and the enabled modules outside Magento.
- Node comes from `NODE_CLI`. The module count is yellow above 25 and red above 50.

### Setting a theme

- `mage_set_theme <theme>` in `core/helpers.sh` is the one place that activates a theme, so every script calls it, even while it can not always set the theme.
- With `yireo/magento2-theme-commands` in the project it runs `theme:change` and flushes the cache.
  Otherwise it points to the admin and returns 1.
  Yireo is one of the default packages of `mage create`, but no script requires it.

### `add module [Vendor/Name] [--hyva|--no-hyva]`

- Asks for anything not given, the Hyvä question defaults to yes when the Hyvä theme module is installed.
- The vendor and name must be valid PHP namespace parts (letters and numbers).
- Creates the module in `app/code/Vendor/MyModule`, which Magento autoloads by namespace (the old script wrongly used the kebab-case name), or when chosen in `package-source/<vendor>/magento2-my-module`, required as `@dev` like a theme.
- The files come from `templates/module`, a Hyvä module also gets `templates/module-hyva` and sequences `Hyva_Theme` instead of `Magento_Theme`.

### `add hyva [--dev]`

- Applies `templates/composer-hyva.json` (license), or with `--dev` `templates/composer-hyva-dev.json` (the Hyvä GitLab repositories as `vcs` repositories over ssh, no token needed).
- Then runs `setup:upgrade` and disables the Magento captcha (not supported by the Hyvä default theme).
  Then sets `Hyva/default` through `mage_set_theme`.
- Building styles is not part of it, that is a separate build action that works for any theme.
- Checkout and commerce are not ported, their GitLab repositories are added with `mage add <url>.git`.

### `add storeinfo`

- Applies `templates/composer-storeinfo.json` (the Siteation StoreInfo core, menus, USPs and payments modules), then runs `setup:upgrade`.

## Templates

- `templates/` is synced to `~/.config/mage/templates` on first use, and again by every `self-update`.
  Commands never fetch them otherwise.
- Running unbuilt (`MAGE_VERSION` is `dev`), mage uses the `templates/` folder of the repository directly.
- A failed sync keeps the previous templates.

### `clean <option>` and `purge`

- Uses the same handler registry as `add`: `MAGE_CLEAN_HANDLERS`, `mage_clean_<name>`, one file per handler in `commands/clean/`.
- Handlers: `files` (generated code, static files and file caches, in one remove call), `redis`, `varnish`, `opensearch` and `sample-files`.
- `clean` without an option, or `clean all`, runs the handlers in `MAGE_CLEAN_ALL` (default `files redis varnish`, the old purge).
  `purge` is an alias for `clean`, so `purge redis` works too.
- `clean help` shows its own help page.
  Unlike `add`, no option is not an error, as cleaning everything is a sensible default.
- `redis` goes through the `clean_redis` env hook.
  Local and Valet share one Redis, so only the keys with the project cache prefixes are deleted.
  Warden and DDEV run Redis per project, so they flush it.
- `opensearch` runs curl through `SEARCH_CURL_CLI`, which Warden and DDEV run inside the OpenSearch container.

### `show <option>`

- Uses the same handler registry as `add` and `clean`: `MAGE_SHOW_HANDLERS`, `mage_show_<name>`, one file per handler in `commands/show/`.
- Without an option it errors with its own help page, like `add`, as there is no sensible default.
- `show stores` replaces `mage stores`: the store base urls through magerun, further arguments go to magerun.
- `show fpc`: the full page cache in use as `builtin` or `varnish`, the counterpart of `set fpc`.
- `show themes`: the same lookup as `show modules` for themes (`app/design` locally), with the parent from each `theme.xml`.
- `show modules` replaces `mage modules`: only the modules of the direct dependencies (`require` and `require-dev`, read with jq) and `app/code`, found by the `registration.php` files up to three folders deep in each package, with disabled modules marked.

### `set <option>`

- The same handler registry: `MAGE_SET_HANDLERS`, `mage_set_<name>`, one file per handler in `commands/set/`.
  Without an option it errors with its help page.
- `set csp` writes the strict storefront CSP (no report only, no inline or eval scripts) with `config:set --lock-env`, instead of magerun `config:env:set` and `app:config:import`, then flushes the config cache.
- `set fpc [builtin|varnish]` sets the full page cache application, an unknown value is refused and errors are no longer hidden.
- `set theme` and `set mage-os` are not ported, `mage theme:change` covers the first.

### `help`, `version`, `self-update`

Kept as they are.

## Build

- `src/build.sh` recursively inlines every `source` line from `src/mage.sh` into `./mage`.
  The build order is therefore defined once, in the entrypoint.
- `src/mage.sh` also runs unbuilt during development, so a rebuild is not needed for every change.
- The version comes from the first `## [x.y.z]` heading in `CHANGELOG.md`.
- The output is checked with `bash -n`, a failed check leaves the existing `mage` untouched.
- `src/build.sh [OUTPUT]` can write elsewhere, which the tests use.

## Tests

A minimal bats suite covering root detection, env selection (with a fake `.env` and stub binaries on `PATH`) and the build output.

## CI

- `.github/workflows/ci.yml` runs on every push and pull request to main.
  Locally, running ShellCheck and the tests is up to the author.
- ShellCheck runs on the built `mage` and `src/build.sh`, with the settings from `.shellcheckrc`.
- The bats suite runs on Ubuntu and on macOS, where it uses the bash 3.2 that macOS ships.

## Shared Redis

- Mage runs `cache:clean`, never `cache:flush`: with Redis, flushing is a `FLUSHDB`, which also clears the cache of the other projects on a shared Redis, cache prefixes or not.
- Sessions and a manual `cache:flush` stay shared on a local or Valet Redis. A Redis instance per project (as proposed in #54) and pinning the search config in `env.php` against imported databases are not part of v3.

## Not ported

- `add hyva checkout` and `add hyva commerce`: add their repositories with `mage add <url>.git`.
- `set theme`, `set mage-os`, `build`, `build hyva`, `browser-sync` and `get`.
- `install` (use `create`), `start`, `new gitignore` and `cleanup` (use `clean`).

## Later

- The `create` extras (BFCache, Hyvä, sample data).
- `import`: run groups of actions from a json file.
- `mage_set_theme` without `yireo/magento2-theme-commands`: look up the theme id (for example with magerun `db:query`) and set `design/theme/theme_id` with `config:set`.
- A build action for theme styles that is not locked to one theme, replacing the old `build hyva`.
- Global packages shared between projects (the old `add dev` and `upd dev`), in a more optimized form.
