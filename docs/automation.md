# Scripts and agents

Mage works the same from a CI job, a script or an AI agent as from a terminal, with a few things to know.

## Questions

Some commands ask questions, such as `mage add theme` for the parent theme.
Without a terminal there is nobody to answer them, so mage stops with an error that names the question, instead of quietly taking a default.

There are three ways to avoid the questions:

- **Pass the answers as options**, such as `mage add theme Vendor/MyTheme --parent=Hyva/default`.
  The pages of the commands list their options.
- **Use `-y` or `--yes`** to take the default of every question, and confirm.
  It works for `create`, `setup`, `add theme`, `add module`, `add sample`, `add admin`, `del`, `enable` and `disable`.
- **Set `MAGE_YES=1`** in the environment, which does the same as `-y` for every command, such as for a whole CI job.

A question without a default, such as the name of a new theme, still needs its option.
Typing the folder name to confirm `mage nuke` and `mage restore` always needs a terminal, so a script can never remove a project by accident.
And `mage add sample hyva` keeps the Luma sample data under `-y`, replacing it needs `--replace-luma`.

Answers can also be piped, one per line, where an empty line takes the default:

```bash
printf 'y\n' | mage add theme Vendor/MyTheme --parent=Magento/blank
```

## Commands that keep running

`mage watch`, `mage build --watch` and `mage log` keep running until they are stopped, so do not run them from a script that waits for them to finish.

## Output

- `mage info --json` and `mage show modules`, `themes` and `logs` with `--json` print json.
  `mage show stores --format=json` passes the format to magerun.
- Colors are left out when the output is not a terminal, or when `NO_COLOR` is set.
- Errors and notices go to stderr, so the output of a command stays clean.
- A failing command exits with a status other than 0.

## Everything else

Anything mage does not know runs `bin/magento`, in the right [environment](environments.md) and from the Magento root.
So `mage cache:clean` works the same with Warden, DDEV, Valet or locally, and from any folder of the project.
