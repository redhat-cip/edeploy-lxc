#!/bin/sh

PUPPETMASTER="192.168.134.48"

while ! rsync -av manifests modules root@${PUPPETMASTER}:/etc/puppet; do
    sleep 1;
done

for i in `cat config.yaml|awk '/^ +address: / {print $2}'`; do
    echo "→ $i"
    ssh root@${PUPPETMASTER} killall puppet
    ssh root@${PUPPETMASTER} puppet master --ignorecache --no-usecacheonfailure --no-splay
    ssh root@$i puppet agent \
        --ignorecache --no-daemonize \
        --no-usecacheonfailure --onetime \
        --debug \
        --server os-ci-test4.lab > ${i}.log 2>&1
done
