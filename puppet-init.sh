#!/bin/bash
set -xe
sudo apt-get install ruby-dev build-essential -y
sudo gem install --no-ri --no-rdoc -v 0.9.10 librarian-puppet
sudo librarian-puppet install --verbose
sudo puppet apply --certname edeploy-ci --modulepath $(pwd)/puppet/modules:$(pwd)/puppet/ext-modules edeploy-ci.pp
