# Launch tests

```bash
bash ./example-ci.sh
```

# Dependencies

## Debian

* bridge-utils
* lxc
* python-yaml
* python-augeas

## Debug with puppet
```puppet
puppet master --no-daemonize --debug
puppet agent --onetime --verbose --ignorecache --no-daemonize --no-usecacheonfailure --no-splay --show_diff --server os-ci-test4.enovance.com
```
