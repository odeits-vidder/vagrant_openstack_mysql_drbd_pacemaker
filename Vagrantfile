# -*- mode: ruby -*-
# vi: set ft=ruby :

# Copyright 2013 Zürcher Hochschule für Angewandte Wissenschaften
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define :grizzly1 do |grizzly1_config|

    grizzly1_config.vm.box = "raring64"
    grizzly1_config.vm.box_url = "https://dl.dropboxusercontent.com/u/547671/thinkstack-raring64.box"

    # grizzly1_config.vm.boot_mode = :gui
    grizzly1_config.vm.network :private_network, ip: "10.1.2.44"
    #grizzly1_config.vm.network :public_network
    grizzly1_config.vm.network :private_network, ip: "192.168.22.11"
    grizzly1_config.vm.host_name = "grizzly1"
    grizzly1_config.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", 1024]
    end
    grizzly1_config.vm.network :forwarded_port, guest: 80, host: 8088
    grizzly1_config.vm.network :forwarded_port, guest: 22, host: 2223

    grizzly1_config.vm.provision :shell, :path => "prep.sh"
    grizzly1_config.vm.provision :puppet do |grizzly1_puppet|
      grizzly1_puppet.module_path = "modules"
      grizzly1_puppet.manifests_path = "manifests"
      grizzly1_puppet.manifest_file = "site1.pp"
      grizzly1_puppet.facter = { "fqdn" => "grizzly1" }
    end

    grizzly1_config.vm.provision :shell, :path => "lvm-setup.sh"
    grizzly1_config.vm.provision :shell, :path => "sshtunnel.sh"
  end

  config.vm.define :grizzly2 do |grizzly2_config|

    grizzly2_config.vm.box = "raring64"
    grizzly2_config.vm.box_url = "https://dl.dropboxusercontent.com/u/547671/thinkstack-raring64.box"

    grizzly2_config.vm.network :private_network, ip: "10.1.2.45"
    #grizzly2_config.vm.network :public_network
    grizzly2_config.vm.network :private_network, ip: "192.168.22.12"
    grizzly2_config.vm.host_name = "grizzly2"
    
    grizzly2_config.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", 1024]
    end
    grizzly2_config.vm.network :forwarded_port, guest: 80, host: 8089
    grizzly2_config.vm.network :forwarded_port, guest: 22, host: 2224

    #grizzly2_config.persistent_storage.location = "~/development/sourcehdd2.vdi"
    #grizzly2_config.persistent_storage.size = 50000

    grizzly2_config.vm.provision :shell, :path => "prep.sh"
    grizzly2_config.vm.provision :puppet do |grizzly2_puppet|
      grizzly2_puppet.module_path = "modules"
      grizzly2_puppet.manifests_path = "manifests"
      grizzly2_puppet.manifest_file = "site2.pp"
      grizzly2_puppet.facter = { "fqdn" => "grizzly2" }
    end
    #grizzly2_config.vm.provision :shell, :path => "script.sh"
    grizzly2_config.vm.provision :shell, :path => "lvm-setup.sh"
    grizzly2_config.vm.provision :shell, :path => "sshtunnel.sh"
    
    grizzly2_config.vm.provision :shell, :path => "corosync-setup.sh"
    grizzly2_config.vm.provision :shell, :path => "drbd-setup.sh"
    grizzly2_config.vm.provision :shell, :path => "mysql_prep.sh"
    grizzly2_config.vm.provision :shell, :path => "pacemaker-prepare.sh"
    grizzly2_config.vm.provision :shell, :path => "network_prepare.sh"
    grizzly2_config.vm.provision :shell, :path => "keystone_ha_prepare.sh"
    grizzly2_config.vm.provision :shell, :path => "glance_ha_prepare.sh"
    grizzly2_config.vm.provision :shell, :path => "quantum_ha_prepare.sh"
    grizzly2_config.vm.provision :shell, :path => "libvirt_ha_prepare.sh"
    grizzly2_config.vm.provision :shell, :path => "nova_ha_prepare.sh"
    grizzly2_config.vm.provision :shell, :path => "iscsi_ha_prepare.sh"
    grizzly2_config.vm.provision :shell, :path => "cinder_ha_prepare.sh"
    grizzly2_config.vm.provision :shell, :path => "horizon_ha_prepare.sh"
  end
end
