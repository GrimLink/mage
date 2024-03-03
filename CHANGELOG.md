# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2024-03-03

### Added

- admin arguments to `mage build` using the `a:` prefix, this allows more admin languages if needed
- log commands for easier log checking
- support for store views to `browser-sync` command, same as with `open` command

### Changed

- Source code is now split, for the bigger functions,
  the main file is the same as always, just now build from the src
- `new theme` and `new module` have been rebuild, now easier to use and extend

### Removed

- composer command aliases
- command `add ray`, better suited for a dotfile aliases
- `mage -h` or `--help` flag versions, it's just `mage help`

## [1.19.0] - 2024-02-23

### Added

- new command `browser-sync` (thanks to @henkvalk)

## [1.18.1] - 2024-01-11

### Added

- new command `add ray`

### Fixed

- Removed fallback set (e.g. empty set) command conflicting with `bin/magento`

## [1.18.0] - 2023-12-13

### Added

- new command to set theme or config

### Removed

- Scoped Valet php

## [1.17.1] - 2023-11-27

### Fixed

- Scoped Valet php, this now has no effect if your using the newest version
- `mage add sample` not setting hyva theme as default if present

## [1.17.0] - 2023-11-11

### Added
- `mage version` or `-v/--version` to just see the version
- new command as shortcut for running both `mage indexer:reindex` and `mage cache:flush`, named `mage reindex`

### Changed
- `new module`/`new-theme` now uses the right prefix for the folder name
- use `app/design/frontend` for `new theme` instead of package-source

## [1.16.0] - 2023-10-31

### Added

- `add checkout` command to easily add the Hyvä Checkout

### Changed

- `add hyva` will use dev mode as default now
- `add hyva` in dev mode will now also install the Luma fallback checkout

## [1.11.0] - 2022-08-29 / [1.15.2] - 2023-10-08

### Added

- new alias for `mage devclean` now you can run the same with `mage watch`
- compat-module-fallback support to `mage add hyva` development version
- aliases for composer install, update and remove, so they can be used with valet php version
- Theme switcher to `add hyva` command
- new command `build` to simplify the `setup:static-content:deploy` command
- new command `translate` to add new translations based on your current folder
- `new i18n` command will now sort all translations alphabetically

### Changed

- Renamed option `help` to `--help` or `-h`
- Add 2 new options to `mage config` using flags,
  `mage config` will act the same if it has not option set,
  See the docs for whats new or use `mage [--help/-h]`
- Use disable customer captcha for add hyva by default
- simplify purge actions, for redis-cli under an if statement
- Use en_US nl_NL as default for `build` command, if empty
- Use 4 jobs as default for `build` command, if empty
- Allow `help` and `self-update` command in any folder location, not just the Magento 2 root folder
- `new theme` now works again, using copy by default
- `new module` now replaces the placeholder fields for you
- Revamped the `new i18n` command to use `bin/magento i18n:collect-phrases` while preserving our customized auto output functionality,
  this change enhances the efficiency of the process and integrates our specialized logic for an optimized experience

### Fixed

- `mage open admin` case where the default store has a different name than default
- Revert of removal of extra if, for valet in cleanup commit, this trows warning in none valet env's
- Watch for Warden
- Fixed force in `build` command
- typos in `new module`
- `mage config` overlappping/overriding `mage config:show`
- `mage new module` command

### Removed

- Disbale hints for add hyva, < Magento 2.4.4
- `mage replaced` command
- `mage devclean` command, we use watch mainly so this only clutter
- simplify purge actions, by removing the c:f action, that is not needed with the manualy action before it
- Command `new translate` and only keep the alias `new i18n` as the new default,
  the `new translate` does not fit and should be `new translation` but I prefer less typing so `new i18n` it is.

## [1.7.0] - 2021-09-11 / [1.10.2] - 2022-07-11

### Added

- [Warden](https://github.com/davidalger/warden) support (thanks to @tdgroot)
- Hyva setup options
- show stores options
- `mage self-update` command
- Support for scoped php version in Laravel Valet 3
- Alias for composer install and require as `mage i`
- Alias for composer remove as `mage rm`
- **Breaking change** dropped static new module and new theme for git templates,
  currently only module works, a theme template will be added in the next release
- Support for cache-clean from [mageTV](https://github.com/mage2tv/magento-cache-clean),
  thx @Vinai for this awesome tool!

### Changed

- Make `mage run` work with [Warden](https://github.com/davidalger/warden)
- Renamed option sample to add sample
- Made all commands with prefix `new` without hyphen,
  see the readme for how to the new command syntax

### Fixed

- `mage open` now also works with [Warden](https://github.com/davidalger/warden)
- Mage open with single quotes in admin url
- Mage run, admin and theme with params
- Mage purge with arguments does not work
- `mage add hyva` now works with [Warden](https://github.com/davidalger/warden)
- `mage add sample` will exit without running in warden and breaking stuff
- Magerun with laravel valet, by removing the valet prefix
- Error in none valet environment
- self update command
- Warden env version for devclean, this not working, so we echo a hint instead
- conflicting commands for composer and magento, both starting with `i`

## [1.2.0] - 2019-11-17 / [1.6.0] - 2021-02-10

### Added

- Purge based on https://github.com/BenButterfield/m2purge
- Static Versioning
- New cmd `new-theme`
- New cmd `new-module`
- New cmd `sample`, for adding sample data
- New cmd `replace`, for removing (optional) core module
- New cmd option `--redis`, to purge
- New cmd `new-customer`

### Changed

- Code quality
- Renamed `admin` cmd to `new-admin`
- Skip steps for `new-admin` and `new-theme` via `--yes` flag
- Casing of variables in `new-theme`

### Removed

- Cms install as this is never used, [Use create-project instead](https://github.com/GrimLink/create-project)

## 1.0.0 - 2019-06-10 / [1.1.0] - 2019-11-06

Initial Release 🎉

### Added
- Open multi store function
- Readme
- Default user name to admin task
- Admin cmd with flag `--yes` for yes to all questions

### Changed

- Info cmd with Magento version

### Removed

- Reindex cmd for native solution

[unreleased]: https://github.com/olivierlacan/keep-a-changelog/compare/2.0.0...HEAD
[2.0.0]: https://github.com/GrimLink/mage/compare/1.19.0...2.0.0
[1.19.0]: https://github.com/GrimLink/mage/compare/1.18.1...1.19.0
[1.18.1]: https://github.com/GrimLink/mage/compare/1.18.0...1.18.1
[1.18.0]: https://github.com/GrimLink/mage/compare/1.17.1...1.18.0
[1.17.1]: https://github.com/GrimLink/mage/compare/1.17.0...1.17.1
[1.17.0]: https://github.com/GrimLink/mage/compare/1.16.0...1.17.0
[1.16.0]: https://github.com/GrimLink/mage/compare/1.15.1...1.16.0
[1.15.2]: https://github.com/GrimLink/mage/compare/1.11.0...1.15.2
[1.11.0]: https://github.com/GrimLink/mage/compare/1.10.2...1.11.0
[1.10.2]: https://github.com/GrimLink/mage/compare/1.7.0...1.10.2
[1.7.0]: https://github.com/GrimLink/mage/compare/1.6.0...1.7.0
[1.6.0]: https://github.com/GrimLink/mage/compare/1.2.0...1.6.0
[1.2.0]: https://github.com/GrimLink/mage/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/GrimLink/mage/compare/1.0.0...1.1.0
