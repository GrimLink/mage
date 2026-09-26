# mage add hyva

Add the [Hyvä Theme](https://www.hyva.io/).

```bash
mage add hyva         # with a license
mage add hyva --dev   # from the Hyvä GitLab
```

## Steps

1. Applies the bundled [composer fragment](../composer-fragments.md) `composer-hyva.json`, or `composer-hyva-dev.json` with `--dev`.
2. Runs `setup:upgrade`.
3. Disables the Magento captcha, which the Hyvä default theme does not support.
4. Tells you to select the `Hyva/default` theme in the admin, under Content, Design, Configuration.

Building the styles is not part of it.

## With a license

`composer-hyva.json` asks for:

* `HYVA_LICENSE_KEY`: your license key, stored in the global composer auth for `hyva-themes.repo.packagist.com`.
* `HYVA_PROJECT`: your project name, the part of your packagist url `https://hyva-themes.repo.packagist.com/<project>/`.

Set `MAGE_VAR_HYVA_LICENSE_KEY` and `MAGE_VAR_HYVA_PROJECT` in the [configuration](../config.md) to answer them with an enter.

## For development

`composer-hyva-dev.json` adds the Hyvä theme repositories of `gitlab.hyva.io` as composer `vcs` repositories. They are read over ssh, so your ssh key needs access to the Hyvä GitLab, no token is asked.
