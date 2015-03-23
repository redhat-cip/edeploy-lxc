#!/bin/bash
#
# copyright (c) 2015 enovance sas <licensing@enovance.com>
#
# licensed under the apache license, version 2.0 (the "license"); you may
# not use this file except in compliance with the license. you may obtain
# a copy of the license at
#
# http://www.apache.org/licenses/license-2.0
#
# unless required by applicable law or agreed to in writing, software
# distributed under the license is distributed on an "as is" basis, without
# warranties or conditions of any kind, either express or implied. see the
# license for the specific language governing permissions and limitations
# under the license.

# This helper script take a qcow2 image URL as input, fetch it then
# extract the tree content to a destination dir.

set -x
set -e

dev=$(sudo losetup -f)

function clean {
    mount | grep "/tmp/tree" && sudo umount /tmp/tree
    losetup | grep $dev && sudo losetup -d $dev || true
    [ -d /tmp/tree ] && rm -Rf /tmp/tree || true
    [ -f /tmp/img.raw ] && rm -f /tmp/img.raw || true
}

function prepare {
    sudo yum install qemu-img kpartx rsync || sudo apt-get install qemu-utils kpartx rsync
    clean
    mkdir /tmp/tree
}

function extract {
    local url=$1
    local dest=$2
    local qcow2=$(echo $1 | awk -F"/" '{print $NF}')
    curl $url -o $qcow2
    qemu-img convert $qcow2 /tmp/img.raw
    [ -d "$dest" ] && sudo sudo rm -Rf $dest
    sudo mkdir -p $dest
    sudo losetup $dev /tmp/img.raw 
    sudo kpartx -a $dev
    sleep 1
    sudo mount /dev/mapper/$(basename $dev)p1 /tmp/tree
    sudo rsync -a /tmp/tree/ $dest/
}

[ -z "$1" ] && { echo "First argument must be an upstream qcow2 url"; exit 1; }
[ -z "$2" ] && { echo "Second argument must be an empty directory"; exit 1; }

prepare
extract $1 $2
clean
