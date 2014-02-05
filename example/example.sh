#!/bin/sh

# In order to avoid SSH complaining about dangling host ssh keys, you
# can add this in your ~/.ssh/config
#
# host os-ci-test*
#     stricthostkeychecking no
#     userknownhostsfile=/dev/null

set -v
set -e

DEBIAN=1
PUPPETMASTER="192.168.134.48"
CONFIG="config.yaml"


sudo ../edeploy-lxc --config $CONFIG restart

for lxc in `sudo lxc-ls|grep os-ci-test`; do
    if -f "/var/lib/lxc/${lxc}/rootfs/var/lib/dpkg/info/openssh-server.postinst"; then
        sudo chroot /var/lib/lxc/${lxc}/rootfs /var/lib/dpkg/info/openssh-server.postinst configure
    fi
    sudo bash -c "echo $(cat /etc/resolv.conf|grep nameserver|tail -1) > /var/lib/lxc/${lxc}/rootfs/etc/resolv.conf"
    sudo bash -c "echo 192.168.134.253 os-ci-vip.lab.enovance.com >> /var/lib/lxc/${lxc}/rootfs/etc/hosts"
done

#if [ -z $DEBIAN ]; then
#    mysqld="mysqld"
#    ssh root@${PUPPETMASTER} yum install -y ruby-mysql rubygem-activerecord
#else
#    mysqld="mysql"
#    ssh root@${PUPPETMASTER} apt-get install --yes ruby-mysql ruby-activerecord
#fi
#ssh root@${PUPPETMASTER} service $mysqld restart
#echo "create database puppet;" | ssh root@${PUPPETMASTER} mysql -uroot
#echo "grant all privileges on puppet.* to puppet@localhost identified by 'password';" | ssh root@${PUPPETMASTER} mysql -uroot

#sudo bash -c 'echo "*" > /var/lib/lxc/os-ci-test4/rootfs/etc/puppet/autosign.conf'
#ssh root@${PUPPETMASTER} " \
#    augtool -s set '/files/etc/puppet/puppet.conf/master/storeconfigs' 'true' ; \
#    augtool -s set '/files/etc/puppet/puppet.conf/master/storeconfigs_backend' 'puppetdb' ; " \
#    || true # augtool returns != 0 on Debian even in case of success
#ssh root@${PUPPETMASTER} puppetdb-ssl-setup
#ssh root@${PUPPETMASTER} sed -i 's,^ssl-host =.*,ssl-host = os-ci-test4.lab.enovance.com,' /etc/puppetdb/conf.d/jetty.ini
#
#ssh root@${PUPPETMASTER} service puppetdb restart
#ssh root@${PUPPETMASTER} puppet master --ignorecache --no-usecacheonfailure --no-splay
#
for i in `cat config.yaml|awk '/^ +address: / {print $2}'`; do
    ssh root@$i '
        cp /bin/true /sbin/mkfs.xfs ; \
        cp /bin/true /sbin/mount.xfs ; \
        cp /bin/true /usr/bin/ovs-vsctl ; \
        service puppet stop'
done

set +e

scp configure-puppet.sh root@${PUPPETMASTER}:
ssh root@${PUPPETMASTER} bash /root/configure-puppet.sh
./refresh.sh
