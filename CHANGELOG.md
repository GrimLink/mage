# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- new commdand `browser-sync` (thanks to @henkvalk)

## [1.18.1] - 2024-01-11
### Added
- new commdand `add ray`

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

## [1.15.2] - 2023-10-08
### Fixed
- `mage new module` command

## [1.15.1] - 2023-08-02
### Fixed
- `mage config` overlappping/overriding `mage config:show`

## [1.15.0] - 2023-08-28
### Added
- `new i18n` command will now sort all translations alphabetically

### Changed
- Revamped the `new i18n` command to use `bin/magento i18n:collect-phrases` while preserving our customized auto output functionality,
  this change enhances the efficiency of the process and integrates our specialized logic for an optimized experience

### Removed
- Command `new translate` and only keep the alias `new i18n` as the new default,
  the `new translate` does not fit and should be `new translation` but I prefer less typing so `new i18n` it is.

## [1.14.0] - 2023-08-28
### Added
- new command `translate` to add new translations based on your current folder

### Changed
- Allow `help` and `self-update` command in any folder location, not just the Magento 2 root folder
- `new theme` now works again, using copy by default
- `new module` now replaces the placeholder fields for you

### Fixed
- typos in `new module`

## [1.13.1] - 2023-08-27
### Changed
- Use en_US nl_NL as default for `build` command, if empty
- Use 4 jobs as default for `build` command, if empty

### Fixed
- Fixed force in `build` command

## [1.13.0] - 2023-08-27
### Added
- Theme switcher to `add hyva` command
- new command `build` to simplify the `setup:static-content:deploy` command

## [1.12.0] - 2023-04-18
### Added
- compat-module-fallback support to `mage add hyva` development version
- aliases for composer install, update and remove, so they can be used with valet php version

### Changed
- Use disable customer captcha for add hyva by default
- simplify purge actions, for redis-cli under an if statement

### Fixed
- Watch for Warden

### Removed
- Disbale hints for add hyva, < Magento 2.4.4
- `mage replaced` command
- `mage devclean` command, we use watch mainly so this only clutter
- simplify purge actions, by removing the c:f action, that is not needed with the manualy action before it

## [1.11.1] - 2022-08-29
### Fixed
- Revert of removal of extra if, for valet in cleanup commit, this trows warning in none valet env's

## [1.11.0] - 2022-08-29
### Added
- new alias for `mage devclean` now you can run the same with `mage watch`

### Changed
- Renamed option `help` to `--help` or `-h`
- Add 2 new options to `mage config` using flags,
  `mage config` will act the same if it has not option set,
  See the docs for whats new or use `mage [--help/-h]`

### Fixed
- `mage open admin` case where the default store has a different name than default

## [1.10.2] - 2022-07-11
### Fixed
- conflicting commands for composer and magento, both starting with `i`

## [1.10.1] - 2022-06-28
### Fixed
- Warden env version for devclean, this not working, so we echo a hint instead

## [1.10.0] - 2022-06-27
### Added
- Support for cache-clean from [mageTV](https://github.com/mage2tv/magento-cache-clean),
  thx @Vinai for this awesome tool!

## [1.9.2] - 2022-06-27
### Fixed
- Error in none valet environment
- self update command

## [1.9.1] - 2022-06-09
### Fixed
- Magerun with laravel valet, by removing the valet prefix

## [1.9.0] - 2022-06-09
### Added
- `mage self-update` command
- Support for scoped php version in Laravel Valet 3
- Alias for composer install and require as `mage i`
- Alias for composer remove as `mage rm`
- **Breaking change** dropped static new module and new theme for git templates,
  currently only module works, a theme template will be added in the next release

## [1.8.3] - 2022-05-30
### Fixes
- `mage add hyva` now works with [Warden](https://github.com/davidalger/warden)
- `mage add sample` will exit without running in warden and breaking stuff

## [1.8.2] - 2022-04-13
### Fixes
- Mage purge with arguments does not work

## [1.8.1] - 2022-02-10
### Fixes
- Mage open with single quotes in admin url
- Mage run, admin and theme with params

## [1.8.0] - 2022-02-07
### Added
- Hyva setup options
- show stores options

### Changed
- Renamed option sample to add sample
- Made all commands with prefix `new` without hypen,
  see the readme for how to the new command syntax

## [1.7.1] - 2021-09-11
### Changed
- Make `mage run` work with [Warden](https://github.com/davidalger/warden)

### Fixed
- `mage open` now also works with [Warden](https://github.com/davidalger/warden)

## [1.7.0] - 2021-09-11
### Added
- [Warden](https://github.com/davidalger/warden) support (thanks to @tdgroot)

## [1.6.0] - 2021-02-10
### Added
- New cmd option `--redis`, to purge
- New cmd `new-customer`

## [1.5.0] - 2020-10-18
### Added
- New cmd `sample`, for adding sample data
- New cmd `replace`, for removing (optional) core module

## [1.4.0] - 2020-08-21
### Added
- New cmd `new-module`

### Changed
- Casing of variables in `new-theme`

## [1.3.0] - 2020-05-16
### Added
- New cmd `new-theme`

### Changed
- Code quality
- Renamed `admin` cmd to `new-admin`
- Skip steps for `new-admin` and `new-theme` via `--yes` flag

### Removed
- Cms install as this is never used, [Use create-project instead](https://github.com/GrimLink/create-project)

## [1.2.0] - 2019-11-17
### Added
- Purge based on https://github.com/BenButterfield/m2purge
- Static Versioning

## [1.1.0] - 2019-11-06
### Added
- Admin cmd with flag `--yes` for yes to all questions

### Changed
- Info cmd with Magento version

### Removed
- Reindex cmd for native solution

## [1.0.2] - 2019-07-14
### Added
- Default user name to admin task

## [1.0.1] - 2019-06-15
### Added
- Open multi store function
- Readme

## [1.0.0] - 2019-06-10
Initial Release 🎉