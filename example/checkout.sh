#!/bin/bash

[ -d manifests ] || git clone git@github.com:enovance/openstack-puppet-ci.git -b master manifests

cd manifests
git pull
cd ..

[ -d modules ] || git clone gitolite@dev.ring.enovance.com:puppet.git -b openstack-havana/master --recursive modules
cd modules
git pull
git submodule init
git submodule sync
git submodule update
cd ..


