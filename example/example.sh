#!/bin/sh

# In order to avoid SSH complaining about dangling host ssh keys, you
# can add this in your ~/.ssh/config
#
# host 192.168.134.*
#     stricthostkeychecking no
#     userknownhostsfile=/dev/null

set -e

[ -d manifests ] || git clone gitolite@git.labs.enovance.com:openstack-puppet-ci.git manifests
cd manifests
git pull
cd ..

[ -d modules ] || git clone git@git.labs.enovance.com:puppet.git modules
cd modules
git pull
git submodule init
git submodule sync
git submodule update
cd ..

sudo ../edeploy-lxc --config config.yaml restart

rsync -av manifests modules root@192.168.134.48:/etc/puppet
ssh root@192.168.134.48 service mysqld restart
echo "create database puppet;" | ssh root@192.168.134.48 mysql -uroot
echo "grant all privileges on puppet.* to puppet@localhost identified by 'password';" | ssh root@192.168.134.48 mysql -uroot
ssh root@192.168.134.48 yum install -y ruby-mysql rubygem-activerecord
# https://ask.puppetlabs.com/question/3853/error-400-on-server-failed-to-submit-replace-facts-command-connection-refused/

sudo bash -c 'echo *.enovance.com > /var/lib/lxc/os-ci-test4/rootfs/etc/puppet/autosign.conf'
ssh root@192.168.134.48 augtool set '/files/etc/puppet/puppet.conf/master/storeconfigs' 'true'
ssh root@192.168.134.48 augtool set '/files/etc/puppet/puppet.conf/master/dbadapter' 'mysql'
ssh root@192.168.134.48 augtool set '/files/etc/puppet/puppet.conf/master/dbuser' 'puppet'
ssh root@192.168.134.48 augtool set '/files/etc/puppet/puppet.conf/master/dbpassword' 'password'
ssh root@192.168.134.48 augtool set '/files/etc/puppet/puppet.conf/master/dbserver' 'localhost'
ssh root@192.168.134.48 puppet master

for i in `cat config.yaml|awk '/^ +address: 192.168.134./ {print $2}'`; do
    ssh root@$i augtool set '/files/etc/puppet/puppet.conf/main/server' 'os-ci-test4.enovance.com'
    ssh root@$i cp /bin/false /usr/bin/yum
    ssh root@$i cp /bin/false /usr/bin/apt-get
    ssh root@$i service puppet stop
    ssh root@$i puppet agent --onetime --no-daemonize --debug
done
