#!/bin/sh

PUPPETMASTER="192.168.134.48"
LOGDIR="/var/www/html/log/$(date +%Y%m%d%H%M)"
echo $LOGDIR

mkdir -p $LOGDIR

while ! rsync -av manifests modules root@${PUPPETMASTER}:/etc/puppet; do
    sleep 1;
done
cat << EOF > $LOGDIR/.htaccess
IndexOptions FancyIndexing NameWidth=* FoldersFirst ScanHTMLTitles DescriptionWidth=*
HeaderName HEADER.html
AllowOverride FileInfo Indexes
Options Indexes SymLinksIfOwnerMatch
EOF


for i in `cat config.yaml|awk '/^ +address: / {print $2}'`; do
    ssh root@${i} '
        cp /bin/false /usr/bin/yum ; \
        cp /bin/true /sbin/mkfs.xfs ; \
        cp /bin/true /sbin/mount.xfs ; \
        cp /bin/true /usr/bin/ovs-vsctl ; \
        cp /bin/true /sbin/parted ; \
        cp /bin/true /sbin/rmmod ; \
        service puppet stop'
    ssh root@${i} 'bash -c "echo nameserver 8.8.4.4 > /etc/resolv.conf"'
done
agent_pid_list=""
ssh root@192.168.134.49 ifconfig eth0:1 192.168.134.253
ssh root@os-ci-test4.lab "killall puppet; puppet master" > $LOGDIR/puppetmaster.log 2>&1 &
echo "begin $(date)<br />" > $LOGDIR/HEADER.html
for i in 192.168.134.49 `cat config.yaml|awk '/^ +address: / {print $2}'`; do
    ssh root@$i 'killall -9 `cat /var/run/puppet/agent.pid`'
    ssh root@$i '
       augtool -s set "/files/etc/puppet/puppet.conf/agent/server" "os-ci-test4.lab.enovance.com"; \
       augtool -s set "/files/etc/puppet/puppet.conf/agent/pluginsync" "true" '


    ssh root@$i puppet agent \
        --ignorecache --waitforcert 60 \
        --no-usecacheonfailure --onetime --no-daemonize \
        --debug \
        --server os-ci-test4.lab.enovance.com >  $LOGDIR/${i}.log 2>&1 &
    agent_pid_list="${agent_pid_list} $!"
done

wait ${agent_pid_list}
echo "end: <strong>$(date)</strong><br />\n" >> $LOGDIR/HEADER.html

for i in `cat config.yaml|awk '/^ +address: / {print $2}'`; do
    cat $LOGDIR/${i}.log |grep Error > /tmp/foo.log
    if [ -s "/tmp/foo.log" ]; then
        cat /tmp/foo.log | ansi2html -p | sed -r 's,background: black;,,i' > $LOGDIR/${i}.error.html
    fi
    cat $LOGDIR/${i}.log | ansi2html -p | sed -r 's,background: black;,,i' > $LOGDIR/${i}.html
done
