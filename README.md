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
2. He calls `edeploy-lxc start`
3. Start the puppet master:
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@10.68.0.48 puppet master --debug --no-daemonize
3. Once he is done, he call `edeploy-lxc stop` to turn off the containers


## supported platform

- Debian 7
