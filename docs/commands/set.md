# mage set

Change a setting of the project.

```bash
mage set csp
mage set fpc varnish
```

`mage set help` lists the options.
Without an option it stops with an error and the same list.

| Option                   | Does                                                                            |
| ------------------------ | ------------------------------------------------------------------------------- |
| `csp`                    | Enforces a strict Content Security Policy on the storefront                     |
| `fpc [builtin\|varnish]` | Sets the full page cache application, `builtin` (also `default`) when not given |

## csp

Turns off the report only mode of the storefront CSP, and disallows inline and eval scripts, as needed by for example a Hyvä CSP theme.
The values are written to `app/etc/env.php` with `config:set --lock-env`, so they are locked in the admin, and the config cache is flushed.

## fpc

Sets `system/full_page_cache/caching_application` to the builtin cache of Magento, or to Varnish.
