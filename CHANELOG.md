# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.8.0] - 2022-02-07
### Added
- Hyva setup options

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