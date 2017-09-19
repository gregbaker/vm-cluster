# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"
NUM_NODES = 3
CORES_PER_NODE = 2
MEMORY_PER_NODE = 1536
SETUP_DATA = {
    'num_nodes' => NUM_NODES,
    'cores_per_node' => CORES_PER_NODE,
    'memory_per_node' => MEMORY_PER_NODE,
    'username' => 'ubuntu' # default username in the VM image
}

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.box_version = '>= 20160921.0.0'
  config.berkshelf.berksfile_path = "cluster_setup/Berksfile"
  config.berkshelf.enabled = true

  config.vm.synced_folder "./", "/home/#{SETUP_DATA['username']}/project"

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--cpus", CORES_PER_NODE, "--memory", MEMORY_PER_NODE]
    vb.customize ["modifyvm", :id, "--uartmode1", "disconnected"] # speed up boot https://bugs.launchpad.net/cloud-images/+bug/1627844
    #vb.gui = true
  end
  
  config.vm.define "master" do |node|
    node.vm.network "private_network", ip: "192.168.7.100"
    node.vm.network "forwarded_port", guest: 8088, host: 8088
    node.vm.network "forwarded_port", guest: 50070, host: 50070
    node.vm.hostname = "master.local"
    node.vm.provision "chef_solo" do |chef|
      chef.cookbooks_path = "."
      chef.add_recipe "cluster_setup"
      chef.json = SETUP_DATA
    end
  end
    
  (1..NUM_NODES).each do |i|
    config.vm.define "hadoop#{i}" do |node|
      node.vm.network "private_network", ip: "192.168.7." + (100+i).to_s
      node.vm.hostname = "hadoop#{i}.local"

      node.vm.provision "chef_solo" do |chef|
        chef.cookbooks_path = "."
        chef.add_recipe "cluster_setup"
        chef.json = SETUP_DATA
      end
    end
  end

end