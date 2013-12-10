#!/bin/sh

# In order to avoid SSH complaining about dangling host ssh keys, you
# can add this in your ~/.ssh/config
#
# host os-ci-test*
#     stricthostkeychecking no
#     userknownhostsfile=/dev/null

set -xe

# For git over ssh
echo 'StrictHostKeyChecking=no' | sudo tee -a /home/$USER/.ssh/config

# Setup hosts file
sudo cp hosts /etc/hosts

# Packages pre-requists packages
sudo apt-get install -y --force-yes -q dnsmasq iptables libvirt-bin \
  lxc lvm2 reiserfsprogs bridge-utils debootstrap python-augeas \
  rsync aufs-tools python libpython2.7 python-yaml

# Mount cgroup
sudo mkdir /cgroup
sudo mount -t cgroup cgroup /cgroup

# Define network (virbr and nat/bridge)
sudo virsh net-define ./network.xml
sudo virsh net-start enovance0

# Build eDeploy role
[ -d manifests ] || git clone git://github.com/enovance/edeploy.git
cd edeploy/build/
sudo make REPOSITORY=http://10.68.0.2:3142/ftp.fr.debian.org/debian DISTRO=wheezy NO_COMPRESSED_FILE=1 openstack-full

# Fetch/clone latest manifests
[ -d manifests ] || git clone gitolite@git.labs.enovance.com:openstack-puppet-ci.git -b master manifests
cd manifests
git pull
cd ..

# Fetch/clone latest module
[ -d modules ] || git clone git@git.labs.enovance.com:puppet.git -b openstack-havana/master --recursive modules
cd modules
git pull
git submodule init
git submodule sync
git submodule update
cd ..

# Launch !
sudo ../edeploy-lxc --config config-ci.yaml restart

rsync -av manifests modules root@os-ci-test4.lab:/etc/puppet
ssh root@os-ci-test4.lab service mysqld restart
echo "create database puppet;" | ssh root@os-ci-test4.lab mysql -uroot
echo "grant all privileges on puppet.* to puppet@localhost identified by 'password';" | ssh root@os-ci-test4.lab mysql -uroot
ssh root@os-ci-test4.lab yum install -y ruby-mysql rubygem-activerecord
# https://ask.puppetlabs.com/question/3853/error-400-on-server-failed-to-submit-replace-facts-command-connection-refused/

sudo bash -c 'echo *.enovance.com > /var/lib/lxc/os-ci-test4/rootfs/etc/puppet/autosign.conf'
ssh root@os-ci-test4.lab augtool set '/files/etc/puppet/puppet.conf/master/storeconfigs' 'true'
ssh root@os-ci-test4.lab augtool set '/files/etc/puppet/puppet.conf/master/dbadapter' 'mysql'
ssh root@os-ci-test4.lab augtool set '/files/etc/puppet/puppet.conf/master/dbuser' 'puppet'
ssh root@os-ci-test4.lab augtool set '/files/etc/puppet/puppet.conf/master/dbpassword' 'password'
ssh root@os-ci-test4.lab augtool set '/files/etc/puppet/puppet.conf/master/dbserver' 'localhost'
ssh root@os-ci-test4.lab puppet master

for i in `cat config.yaml|awk '/^ +address: 192.168.134./ {print $2}'`; do
    ssh root@$i augtool set '/files/etc/puppet/puppet.conf/main/server' 'os-ci-test4.enovance.com'
    ssh root@$i cp /bin/false /usr/bin/yum
    ssh root@$i cp /bin/false /usr/bin/apt-get
    ssh root@$i service puppet stop
    ssh root@$i puppet agent --onetime --no-daemonize --debug
done
