#!/bin/bash

[ -d manifests ] || git clone git@github.com:enovance/openstack-puppet-ci.git -b master manifests
#[ -d manifests ] || git clone git@github.com:enovance/openstack-puppet-deveryware.git -b master manifests

cd manifests
git checkout master
git fetch --all
git branch -m work work_$(date +%Y%m%d%H%M)
git checkout -b work origin/master
git merge -m "bob" origin/feature/19/goneri
cd ..

[ -d modules ] || git clone gitolite@dev.ring.enovance.com:puppet.git -b openstack-havana/master --recursive modules
cd modules
git pull
git submodule init
git submodule sync
git submodule update
cd cloud
git checkout master
git branch -m work work_$(date +%Y%m%d%H%M)
git checkout -b work origin/master
git merge -m "bob" origin/feature/39/goneri origin/feature/68/goneri


