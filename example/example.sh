#!/bin/sh

# In order to avoid SSH complaining about dangling host ssh keys, you
# can add this in your ~/.ssh/config
#
# host os-ci-test*
#     stricthostkeychecking no
#     userknownhostsfile=/dev/null

set -e

show_usage() {
  echo "Usage:
    `basename $0`
    `basename $0` -c config.yaml -p os-ci-test4.lab"
    exit 1
}

SCRATCH=0
DEBIAN=0

while getopts "p:c:sdh" opt; do
  case $opt in
    p)
      PUPPETMASTER=$OPTARG
      ;;
    c)
      CONFIG=$OPTARG
      ;;
    s)
      SCRATCH=1
      ;;
    d)
      DEBIAN=1
      ;;
    h)
      show_usage
      ;;
    *)
      echo "go ahead"
      exit 1
      ;;
  esac
done

if [ -z "$PUPPETMASTER" ];then
  PUPPETMASTER="os-ci-test4.lab"
fi

if [ -z "$CONFIG" ];then
  CONFIG="config.yaml"
fi

if [ $SCRATCH -eq 1 ]; then
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
fi

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

sudo ../edeploy-lxc --config $CONFIG restart

for lxc in `sudo lxc-ls|grep os-ci-test`; do
    sudo cp -v /etc/resolv.conf /var/lib/lxc/$lxc/rootfs/etc/resolv.conf
done

while ! rsync -av manifests modules root@${PUPPETMASTER}:/etc/puppet; do
    sleep 1;
done

if [ $DEBIAN -eq 1 ]; then
    mysqld="mysqld"
    ssh root@${PUPPETMASTER} yum install -y ruby-mysql rubygem-activerecord
else
    mysqld="mysql"
    ssh root@${PUPPETMASTER} apt-get install --yes ruby-mysql ruby-activerecord
fi
ssh root@${PUPPETMASTER} service $mysqld restart
echo "create database puppet;" | ssh root@${PUPPETMASTER} mysql -uroot
echo "grant all privileges on puppet.* to puppet@localhost identified by 'password';" | ssh root@${PUPPETMASTER} mysql -uroot

sudo bash -c 'echo *.lab > /var/lib/lxc/os-ci-test4/rootfs/etc/puppet/autosign.conf'
ssh root@${PUPPETMASTER} " \
    augtool -s set '/files/etc/puppet/puppet.conf/master/storeconfigs' 'true' ; \
    augtool -s set '/files/etc/puppet/puppet.conf/master/dbadapter' 'mysql' ; \
    augtool -s set '/files/etc/puppet/puppet.conf/master/dbuser' 'puppet' ; \
    augtool -s set '/files/etc/puppet/puppet.conf/master/dbpassword' 'password' ; \
    augtool -s set '/files/etc/puppet/puppet.conf/master/dbserver' 'localhost' : \
    augtool -s set '/files/etc/puppet/puppet.conf/master/storeconfigs' 'true'" \
    || true # augtool returns != 0 on Debian even in case of success
ssh root@${PUPPETMASTER} puppet master --ignorecache --no-usecacheonfailure --no-splay

for i in `cat config.yaml|awk '/^ +address: 192.168.134./ {print $2}'`; do
    ssh root@$i 'cp /bin/false /usr/bin/yum ; \
        cp /bin/false /usr/bin/apt-get ; \
        cp /bin/true /sbin/mkfs.xfs ; \
        cp /bin/true /sbin/mount.xfs ; \
        cp /bin/true /usr/bin/ovs-vsctl ; \
        chmod -x /usr/lib/apt/methods/http ; \
        apt-get install --yes ruby-mysql ; \
        service puppet stop'
done


while true; do
    for i in `cat config.yaml|awk '/^ +address: 192.168.134./ {print $2}'`; do
        ssh root@$i puppet agent --debug \
            --ignorecache --no-daemonize \
            --no-usecacheonfailure --onetime \
            --server ${PUPPETMASTER}
    done
done
