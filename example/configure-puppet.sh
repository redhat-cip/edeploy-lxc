#!/bin/bash
#
# Copyright (C) 2014 eNovance SAS <licensing@enovance.com>
#
# Author: Frederic Lepied <frederic.lepied@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# Purpose:
#
# To be run on the puppet master to do the initial configuration

set -e
set -x

if [ $(id -u) != 0 ]; then
    exec sudo -i "$0" "$@"
fi

#if [ $# != 2 ]; then
#    echo "Usage: $0 <modules tarball> <manifests tarball>" 1>&2
#    exit 1
#fi
#
#MODULES=$1
#MANIFESTS=$2
#
configure_hostname() {
    if hostname -f; then
	FQDN=$(hostname -f)
    else
	HOSTNAME=$(hostname)
	
	case $HOSTNAME in
	    *.*)
		SHORT=$(sed 's/\..*//' <<< $HOSTNAME)
		;;
	    *)
		SHORT=$HOSTNAME
		HOSTNAME=$HOSTNAME.local
		;;
	esac

	eval "$(facter |fgrep 'ipaddress =>' | sed 's/ => /=/')"

	if ! grep -q $ipaddress /etc/hosts; then
	    echo "$ipaddress	$SHORT" >> /etc/hosts
	fi

	FQDN=$SHORT
    fi
}

detect_os() {
    OS=$(lsb_release -i -s)
    case $OS in
	Debian|Ubuntu)
	    WEB_SERVER="apache2"
	    ;;
	CentOS|RedHatEnterpriseServer)
	    WEB_SERVER="httpd"
	    ;;
	*)
	    echo "Operating System not supported."
	    exit 1
	    ;;
    esac
    RELEASE=$(lsb_release -c -s)
    DIST_RELEASE=$(lsb_release -s -r)
}

configure_puppet() {
    service puppetmaster stop
    service puppetdb stop
    service $WEB_SERVER stop

    cat > /etc/puppet/puppet.conf <<EOF
[main]
logdir=/var/log/puppet
vardir=/var/lib/puppet
ssldir=/var/lib/puppet/ssl
rundir=/var/run/puppet
factpath=\$vardir/lib/facter
templatedir=\$confdir/templates

[master]
ssl_client_header = SSL_CLIENT_S_DN
ssl_client_verify_header = SSL_CLIENT_VERIFY
storeconfigs=true
storeconfigs_backend=puppetdb
reports=store,puppetdb

[agent]
pluginsync=true
certname=${FQDN}
server=${FQDN}

[main]
server = ${FQDN}
port = 8081
EOF

    cat > /etc/puppet/routes.yaml <<EOF
---
master:
  facts:
    terminus: puppetdb
    cache: yaml
EOF

    cat > /etc/puppetdb/conf.d/jetty.ini <<EOF
[jetty]
port = 8080

ssl-host = ${FQDN}
ssl-port = 8081
ssl-key = /etc/puppetdb/ssl/key.pem
ssl-cert = /etc/puppetdb/ssl/cert.pem
ssl-ca-cert = /etc/puppetdb/ssl/ca.pem
EOF

    cat > /etc/puppet/puppetdb.conf <<EOF
[main]
server = ${FQDN}
port = 8081
EOF

    sed -i -e "s!SSLCertificateFile.*!SSLCertificateFile /var/lib/puppet/ssl/certs/${FQDN}.pem!" -e "s!SSLCertificateKeyFile.*!SSLCertificateKeyFile /var/lib/puppet/ssl/private_keys/${FQDN}.pem!" /etc/apache2/sites-available/puppetmaster

    rm -rf /var/lib/puppet/ssl && puppet cert generate ${FQDN}

    cp /var/lib/puppet/ssl/private_keys/$(hostname -f).pem /etc/puppetdb/ssl/key.pem && chown puppetdb:puppetdb /etc/puppetdb/ssl/key.pem
    cp /var/lib/puppet/ssl/certs/$(hostname -f).pem /etc/puppetdb/ssl/cert.pem && chown puppetdb:puppetdb /etc/puppetdb/ssl/cert.pem
    cp /var/lib/puppet/ssl/certs/ca.pem /etc/puppetdb/ssl/ca.pem && chown puppetdb:puppetdb /etc/puppetdb/ssl/ca.pem

    if [ $OS == "Debian" ] || [ $OS == "Ubuntu" ]; then
	echo '. /etc/default/locale' | tee --append /etc/apache2/envvars
    fi

#    rm -rf /etc/puppet/modules
#    rm -rf /etc/puppet/manifests
#    tar xvf $MANIFESTS -C /etc/puppet
#    tar xvf $MODULES -C /etc/puppet
    tee -a /etc/puppet/autosign.conf <<< '*'

    puppet resource service puppetmaster ensure=stopped enable=false
    service puppetdb start
    puppet resource service puppetdb ensure=running enable=true
    a2ensite puppetmaster
    service $WEB_SERVER start

    # puppetdb is slow to start so try multiple times to reach it
    NUM=10
    RC=1
    while [ $NUM -gt 0 ]; do
	if puppet agent --onetime --verbose --ignorecache --no-daemonize --no-usecacheonfailure --no-splay --show_diff; then
	    RC=0
	    echo "Puppet Server UP and RUNNING!"
	    break
	fi
	NUM=$(($NUM - 1))
	sleep 10
    done
}

configure_hostname
detect_os
configure_puppet

rm -f "$0" $MODULES $MANIFESTS
exit $RC

# configure-puppet.sh ends here
