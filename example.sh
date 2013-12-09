#!/bin/sh

set -e

~/enovance/puppet-edeploy/update.sh
sudo ./edeploy-lxc restart

rsync -av /home/goneri/enovance/puppet-edeploy/* root@10.68.0.48:/etc/puppet 
ssh root@10.68.0.48 service mysqld restart
echo "create database puppet;" | ssh root@10.68.0.48 mysql -uroot
echo "grant all privileges on puppet.* to puppet@localhost identified by 'password';" | ssh root@10.68.0.48 mysql -uroot
ssh root@10.68.0.48 yum install -y ruby-mysql rubygem-activerecord
# https://ask.puppetlabs.com/question/3853/error-400-on-server-failed-to-submit-replace-facts-command-connection-refused/

sudo bash -c 'echo *.enovance.com > /var/lib/lxc/os-ci-test4/rootfs/etc/puppet/autosign.conf'
ssh root@10.68.0.48 augtool set '/files/etc/puppet/puppet.conf/master/storeconfigs' 'true'
ssh root@10.68.0.48 augtool set '/files/etc/puppet/puppet.conf/master/dbadapter' 'mysql'
ssh root@10.68.0.48 augtool set '/files/etc/puppet/puppet.conf/master/dbuser' 'puppet'
ssh root@10.68.0.48 augtool set '/files/etc/puppet/puppet.conf/master/dbpassword' 'password'
ssh root@10.68.0.48 augtool set '/files/etc/puppet/puppet.conf/master/dbserver' 'localhost'
ssh root@10.68.0.48 puppet master

for i in `cat config.yaml|awk '/^ +address: 10.68./ {print $2}'`; do
    ssh root@$i augtool set '/files/etc/puppet/puppet.conf/main/server' 'os-ci-test4.enovance.com'
    ssh root@$i cp /bin/false /usr/bin/yum
    ssh root@$i cp /bin/false /usr/bin/apt-get
    ssh root@$i service puppet stop
    ssh root@$i puppet agent --onetime --no-daemonize --debug
done
