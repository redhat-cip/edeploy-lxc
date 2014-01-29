# eDeploy LXC

eDeploy LXC allows you to deploy quickly an test infrastructure within LXC
container.

It will deploy a set of LXC containers based on:

- eDeploy roles
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
* rsync
* aufs-tools
* python (testd with 2.7)
* python-augeas
* python-yaml

## Warning

_Access to host loopback devices is possible from the containers (RW)._

### Network

Bridge has to be create first. You can use libvirt for that or do it manually.

For example `/etc/libvirt/qemu/networks/enovance0.xml`:
```xml
<network>
  <name>virbr1</name>
  <uuid>bf1c0ff4-a3b1-4357-bd7c-3195c7fcd789</uuid>
  <forward dev='eth0' mode='nat'>
    <interface dev='eth0'/>
  </forward>
  <bridge name='virbr1' stp='on' delay='0'/>
  <mac address='52:54:00:dd:c7:2d'/>
  <ip address='192.168.134.1' netmask='255.255.255.0'>
  </ip>
</network>
```

### How to enable LXC

#### Debian Testing/Sid

* Enable cgroup in `/etc/default/libvirt-bin`:

`mount_cgroups=yes`

* Enable memory cgroup in grub `/etc/default/grub`:

`GRUB_CMDLINE_LINUX="cgroup_enable=memory"` and run `update-grub2`

## supported platform

- Debian 7
