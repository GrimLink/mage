# mage add admin

Create an admin user.

```bash
mage add admin
mage add admin -y
```

It asks for the email, first name, last name, username and password.
The defaults are the `MAGE_ADMIN_*` settings from the [configuration](../config.md), the same user `mage setup` creates, so an empty answer uses them.
The password input is hidden.

With `-y` or `--yes` it uses the defaults without asking.
Magento stops with an error when the username or email is already taken.

# mage add customer

Create a customer, through [n98-magerun2](https://github.com/netz98/n98-magerun2), as Magento has no command for it.

```bash
mage add customer
mage add customer me@example.com secret123 Me Customer base
```

Without arguments magerun asks for the email, password, first name, last name and website.
Arguments go to its `customer:create` as is.
