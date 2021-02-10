# Changelog

## Unreleased
* ADD:
  * new cmd option `--redis`, to purge
  * new cmd `new-customer`

## 1.5.0 - (2020-10-18)
* ADD:
  * new cmd `sample`, for adding sample data
  * new cmd `replace`, for removing (optional) core module

## 1.4.0 - (2020-08-21)
* ADD:
  * new cmd `new-module`
* IMP:
  * casing of variables in `new-theme`

## 1.3.0 - (2020-05-16)
* ADD:
  * new cmd `new-theme`
* IMP:
  * code quality
  * renamed `admin` cmd to `new-admin`
  * Skip steps for `new-admin` and `new-theme` via `--yes` flag
* DEL: cms install as this is never used,
  [Use create-project instead](https://github.com/GrimLink/create-project)

## 1.2.0 - (2019-11-17)
* ADD:
  * purge based on https://github.com/BenButterfield/m2purge
  * Static Versioning

## 1.1.0 - (2019-11-06)
* ADD: admin cmd with flag `--yes` for yes to all questions
* IMP: info cmd with Magento version
* DEL: reindex cmd for native solution

## 1.0.2 - (2019-07-14)
* ADD: default user name to admin task

## 1.0.1 - (2019-06-15)
* IMP:
  * open multi store function
  * readme

## 1.0.0 - (2019-06-10)
* Initial commit