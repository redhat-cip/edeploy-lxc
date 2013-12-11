#!/bin/sh

# In order to avoid SSH complaining about dangling host ssh keys, you
# can add this in your ~/.ssh/config
#
# host os-ci-test*
#     stricthostkeychecking no
#     userknownhostsfile=/dev/null

set -e

PUPPETMASTER="os-ci-test4.lab"
DEBIAN=1

[ -d manifests ] || git clone gitolite@git.labs.enovance.com:openstack-puppet-ci.git -b master manifests

cd manifests
git pull
cd ..

[ -d modules ] || git clone git@git.labs.enovance.com:puppet.git -b openstack-havana/master --recursive modules
cd modules
git pull
git submodule init
git submodule sync
git submodule update
cd ..

sudo ../edeploy-lxc --config config.yaml restart

if [ -z $DEBIAN ]; then
    mysqld="mysqld"
    ssh root@${PUPPETMASTER} yum install -y ruby-mysql rubygem-activerecord
else
    mysqld="mysql"
    ssh root@${PUPPETMASTER} apt-get install --yes ruby-mysql ruby-activerecord
fi

rsync -av manifests modules root@${PUPPETMASTER}:/etc/puppet
ssh root@${PUPPETMASTER} service $mysqld restart
echo "create database puppet;" | ssh root@${PUPPETMASTER} mysql -uroot
echo "grant all privileges on puppet.* to puppet@localhost identified by 'password';" | ssh root@${PUPPETMASTER} mysql -uroot


sudo bash -c 'echo *.enovance.com > /var/lib/lxc/os-ci-test4/rootfs/etc/puppet/autosign.conf'
set +e
ssh root@${PUPPETMASTER} augtool -s set '/files/etc/puppet/puppet.conf/master/storeconfigs' 'true'
ssh root@${PUPPETMASTER} augtool -s set '/files/etc/puppet/puppet.conf/master/dbadapter' 'mysql'
ssh root@${PUPPETMASTER} augtool -s set '/files/etc/puppet/puppet.conf/master/dbuser' 'puppet'
ssh root@${PUPPETMASTER} augtool -s set '/files/etc/puppet/puppet.conf/master/dbpassword' 'password'
ssh root@${PUPPETMASTER} augtool -s set '/files/etc/puppet/puppet.conf/master/dbserver' 'localhost'
ssh root@${PUPPETMASTER} augtool -s set '/files/etc/puppet/puppet.conf/master/storeconfigs' 'true'
set -e
ssh root@${PUPPETMASTER} puppet master

for i in `cat config.yaml|awk '/^ +address: 192.168.134./ {print $2}'`; do
    set +e
    ssh root@$i augtool -s set '/files/etc/puppet/puppet.conf/main/server' 'os-ci-test4.enovance.com'
    set -e
#    ssh root@$i cp /bin/false /usr/bin/yum
#    ssh root@$i cp /bin/false /usr/bin/apt-get
    ssh root@$i service puppet stop
    ssh root@$i puppet agent --onetime --no-daemonize --debug
done
