# eDeploy LXC

eDeploy LXC allows you to deploy quickly an test infrastructure within LXC
container.

It will deploy a set of LXC containers based on:

- a eDeploy role
- IP and host from a YAML conf

## use case

John needs to validate the new Puppet configuration but to do so, it
has to deploy 6 differents virtual machines.

1. He prepares a conf.yaml file with:
    - the domain
    - the name of a bridge interface
    - a list of virtual machine (IP and name)
2. He calls `edeploy-lxc start` as root
3. Start the puppet master, for example:
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@10.68.0.48 puppet master --debug --no-daemonize
3. Once he is done, he call `edeploy-lxc stop` as root to turn off the containers

## requirements

* lxc
* python (testd with 2.7)
* python-augeas
* python-yaml

Bridge has to be create first. You can use libvirt for that or do it manually.


## supported platform

- Debian 7
