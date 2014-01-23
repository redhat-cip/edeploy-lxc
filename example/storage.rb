#!/usr/bin/env ruby

hosts = ['os-ci-test9', 'os-ci-test10', 'os-ci-test11']
devices = ['sdb', 'sdc', 'sdd']


`losetup -a`.each_line do |line|
    /^(\/dev\/loop\d+).*\((.+)\)$/.match(line) do
        dev=$1
        file=$2
        `losetup -d #{dev}`
        File.unlink(file)
    end
end

hosts.each do |host|
    puts host
    devices.each do |device|
        file="/tmp/#{host}_#{device}.raw"
        lo_dev=`losetup -f`.chomp
        lo_dev_id=/\/dev\/loop(\d+)/.match(lo_dev)[1]
        `qemu-img create #{file} 10G`

        puts `losetup #{lo_dev} #{file}`

        puts "mknod /var/lib/lxc/#{host}/rootfs/dev/#{device} block 7 #{lo_dev_id}"
        puts `mknod /var/lib/lxc/#{host}/rootfs/dev/#{device} block 7 #{lo_dev_id}`
    end
end
