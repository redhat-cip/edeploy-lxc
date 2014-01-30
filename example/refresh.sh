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

echo "begin $(date)<br />" > $LOGDIR/HEADER.html
for i in 192.168.134.49 `cat config.yaml|awk '/^ +address: / {print $2}'`; do
    ssh root@$i puppet agent \
        --ignorecache --no-daemonize \
        --no-usecacheonfailure --onetime \
        --debug \
        --server os-ci-test4.lab.enovance.com >  $LOGDIR/${i}.log 2>&1
    cat $LOGDIR/${i}.log |grep Error | ansi2html -p > $LOGDIR/${i}.error.html
    cat $LOGDIR/${i}.log | ansi2html -p > $LOGDIR/${i}.html
done
echo "end: <strong>$(date)</strong><br />\n" >> $LOGDIR/HEADER.html
