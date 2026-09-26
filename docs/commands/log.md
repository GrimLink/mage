# mage log

Follow a log in `var/log`.

```bash
mage log            # var/log/debug.log
mage log system     # var/log/system.log
mage log exception.log
```

The name works with or without `.log`, and defaults to `debug`. It shows the last lines, then follows the log until you stop it. When the log does not exist, it lists the ones there are.

To list the logs with their size, use [`mage show logs`](show.md). To delete them, use [`mage clean logs`](clean.md).
