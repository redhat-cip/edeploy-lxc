# eDeploy LXC

eDeploy LXC allows you to deploy quickly an test infrastructure within LXC
container. A base file system tree is used as a base for a container
using an addtionnal layer AUFS or overlayFS.

It will deploy a set of LXC containers based on:

- A pre existing file system tree
- IP and host from a YAML conf

## use case

John needs to validate the new Puppet configuration but to do so, it
has to deploy 6 differents virtual machines.

1. He prepares a conf.yaml file with:
    - the domain
    - the name of a bridge interface
    - a list of virtual machine (IP, name, role and cloudinit file)
2. He calls `edeploy-lxc --config=conf.yaml start` as root
3. Start the puppet master, for example:
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@10.68.0.48 puppet master --debug --no-daemonize
3. Once he is done, he call `edeploy-lxc stop` as root to turn off the containers

## requirements

* lxc
* aufs-tools (if the kernel does not include overlayFS)
* debootstrap (if your are going to deploy ubuntu or debian containers)
* python (tested with 2.7)
* python-yaml

## Install target FS tree

In the configuration file "edeploy.dir" is the base path to find the base FS tree then
for each hosts you can specify a "role". The script will use edeploy.dir/role as base
for mounting the overlay FS. In order to prepare this directory you can use the create_base.sh
script as follow:

./create_base.sh http://cloud-images.ubuntu.com/releases/14.04/release/ubuntu-14.04-server-cloudimg-amd64-disk1.img \
 /var/lib/debootstrap/ubuntu14.04

## Warning

_Access to host loopback devices is possible from the containers (RW)._

edeploy-lxc stop will wipe all the container data.

## Cloud-init

Custom cloud-init files can also be used per virtual machines. The file path
must be references in the conf.yaml with the key 'cloudinit'.

They will be copied to /etc/cloud/cloud.cfg.d/ in order to be used as a flat
file data-source.

## Give internet access to the containers

 ./firewall.sh

## supported target

- Debian 7
- Centos 7
- Ubuntu 14.04

## TODO:

 - support a soft stop/restart that does not wipe the data.
