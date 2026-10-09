# Security Policy

## Supported versions

Only the latest release of mage receives security fixes.

| Version | Supported |
| ------- | --------- |
| 3.x     | Yes       |
| < 3.0   | No        |

## Reporting a vulnerability

Report a vulnerability through a [private security advisory](https://github.com/GrimLink/mage/security/advisories/new) on GitHub.
Please do not open a public issue for it.

Expect a first response within a few working days, stating whether the report is accepted and when a fix can be expected.

## What mage does

Mage is a shell script that runs as your own user, with the rights you already have.
We try to keep it from doing anything you did not ask for:

- **Downloads:** mage only downloads from this repository over https, the script itself with `mage self-update`, and the templates on first use and with `self-update`.
- **Credentials:** secrets, such as license keys, go to the global composer auth, never to a project and never to the mage config.
  Answers that are saved in the config are written as text, so they can not run as code.
- **The config file:** mage only loads `~/.config/mage/config` when it is owned by you and others can not change it, and never loads a config from a project, so cloning a repository can not run code through mage.
- **Removing things:** `mage nuke` and `mage restore` ask you to type the folder name, which `-y` and `MAGE_YES` never answer.
- **Without a terminal:** a question without an answer stops mage, instead of quietly taking a default.

## What is up to you

Mage applies what you give it as is, so the following is your own responsibility, and not something we can be held responsible for:

- **Your config:** `~/.config/mage/config` is bash, and runs as code every time mage starts.
  Mage checks who can change the file, not what is in it.
  Anything you add to it, settings, code or values, is yours to manage.
- **What you add to a project:** composer fragments, git repositories, patches and packages that you add with `mage add` are used as given.
  Review them, and the repositories and credentials they bring, before you add them.
- **Third party packages:** the default packages of `mage create`, the Hyvä packages and the sample data come from their own maintainers.
  Report a vulnerability in those to their maintainers.
- **Your environment:** mage runs `bin/magento`, composer, npm and the tools of your environment, such as Warden or DDEV.
  Keeping those up to date is up to you.

A vulnerability in mage itself, such as mage running code from a file it should not trust, is something we want to hear about.
