# Composer fragments

A composer fragment is a json file with a part of a `composer.json`, which `mage add` applies to the project:

```bash
mage add composer-hyva.json
mage add ~/projects/shared/composer-payments.json
```

The name of the file is free, it only has to end in `.json`.
The path is resolved from the folder you run mage in, and files outside the project work too.
It requires [jq](https://jqlang.org/).

## Format

```json
{
  "description": "Hyvä Theme",
  "auth": {
    "http-basic": {
      "hyva-themes.repo.packagist.com": {
        "username": "token",
        "password": "{{HYVA_LICENSE_KEY}}"
      }
    }
  },
  "repositories": {
    "private-packagist": {
      "type": "composer",
      "url": "https://hyva-themes.repo.packagist.com/{{HYVA_PROJECT}}/"
    }
  },
  "config": {
    "allow-plugins": {
      "vendor/plugin": true
    }
  },
  "require": {
    "hyva-themes/magento2-default-theme": "*"
  },
  "require-dev": {}
}
```

Every key is optional.
Other keys are skipped with a warning, which catches a typo such as `requires`.

| Key            | Applied as                                                                                            |
| -------------- | ----------------------------------------------------------------------------------------------------- |
| `description`  | Shown when applying                                                                                   |
| `auth`         | `composer config --global --auth`, see below                                                          |
| `repositories` | `composer config --append repositories.<name> <json>`, one per repository                             |
| `config`       | `composer config <key> <value>`, nested keys become dotted keys such as `allow-plugins.vendor/plugin` |
| `require`      | One `composer require` with all packages                                                              |
| `require-dev`  | One `composer require --dev` with all packages                                                        |

They are applied in the order of the table, so the packages can use the credentials and repositories.
The first failure stops the rest.

### repositories

An object keyed by the repository name, as `composer config` needs a name for each.
A list of repositories, as allowed in a `composer.json`, is refused.
They are appended after the existing repositories, so the `local-packages` path repository of `package-source` stays in front and local packages keep priority.

### config

Values are strings, numbers or booleans.
Lists are skipped with a warning.

### auth

The same format as composer's `auth.json`.
`http-basic` takes a `username` and `password`, the other types, such as `gitlab-token`, `github-oauth` and `bearer`, take a single token:

```json
{
  "auth": {
    "gitlab-token": {
      "gitlab.example.com": "{{GITLAB_TOKEN}}"
    }
  }
}
```

Credentials go to the global composer auth, never to the project, as the `auth.json` of a project is easily committed.
A credential the global auth already has for that type and host is kept, and its placeholders are not asked.
To change one, run `composer config --global --auth <type>.<host> ...` yourself.
Composer keeps one credential per host, so projects with different keys for the same host overwrite each other.

## Placeholders

`{{NAME}}` placeholders, with uppercase letters, digits and underscores, are asked when the fragment is applied.
The answer to each is used everywhere it occurs.

- Placeholders inside `auth` are secrets, their input is hidden.
- `MAGE_VAR_<NAME>` in the [configuration](config.md) gives the default answer, so an empty answer uses it.
- An empty answer without a default stops the command.
- Answers are escaped for json, so quotes are safe.

## Bundled fragments

Mage ships these fragments in its [templates](templates.md), used by the matching `add` handlers:

- `composer-hyva.json`: Hyvä with a license.
- `composer-hyva-dev.json`: Hyvä from the Hyvä GitLab.
- `composer-hyva-sample-dev.json`: the repositories of the Koti sample data on the Hyvä GitLab.
- `composer-storeinfo.json`: the Siteation StoreInfo modules.
