node /edeploy-ci/ {

  class { 'libvirt':
    defaultnetwork => false,
  }

  $virt_net = {
    'address' => '192.168.0.1',
    'netmask' => '255.255.255.0',
  }

  libvirt::network { 'enoci0':
    forward_mode => 'nat',
    forward_dev  => 'eth0',
    autostart    => true,
    bridge       => 'virbr1',
    ip           => [$virt_net],
  }

}
