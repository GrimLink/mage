# mage add hyva

Add the [Hyvä Theme](https://www.hyva.io/) and make it the active theme where possible.

```bash
mage add hyva         # with a license
mage add hyva --dev   # from the Hyvä GitLab
```

## Steps

1. Applies the bundled [composer fragment](../composer-fragments.md) `composer-hyva.json`, or `composer-hyva-dev.json` with `--dev`.
2. Runs `setup:upgrade`.
3. Disables the Magento captcha, which the Hyvä default theme does not support.
4. Switches to `Hyva/default` when the project has `yireo/magento2-theme-commands`, otherwise it tells you to select the theme in the admin. Mage does not install that module itself.

Building the styles is not part of it.

## With a license

`composer-hyva.json` asks for:

* `HYVA_LICENSE_KEY`: your license key, stored in the global composer auth for `hyva-themes.repo.packagist.com`.
* `HYVA_PROJECT`: your project name, the part of your packagist url `https://hyva-themes.repo.packagist.com/<project>/`.

Set `MAGE_VAR_HYVA_LICENSE_KEY` and `MAGE_VAR_HYVA_PROJECT` in the [configuration](../config.md) to answer them with an enter.

## For development

`composer-hyva-dev.json` adds the Hyvä theme repositories of `gitlab.hyva.io` as composer `vcs` repositories. They are read over ssh, so your ssh key needs access to the Hyvä GitLab, no token is asked.
