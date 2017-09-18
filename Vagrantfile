# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"
NUM_NODES = 2
SETUP_DATA = { 'num_nodes' => NUM_NODES, 'username' => 'ubuntu' }

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.box_version = '>= 20160921.0.0'
  config.berkshelf.berksfile_path = "cluster_setup/Berksfile"
  config.berkshelf.enabled = true

  #config.vm.synced_folder "./", "/home/vagrant/project"

  cpus = "1"
  memory = "1536" # MB
  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--cpus", cpus, "--memory", memory]
    vb.customize ["modifyvm", :id, "--uartmode1", "disconnected"] # speed up boot https://bugs.launchpad.net/cloud-images/+bug/1627844
    #vb.gui = true
  end
  
  config.vm.define "master" do |node|
    node.vm.network "private_network", ip: "192.168.7.100"
    node.vm.hostname = "master.local"
    node.vm.provision "chef_solo" do |chef|
      chef.cookbooks_path = "."
      #chef.add_role("master")
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
        #chef.add_role("worker")
        chef.add_recipe "cluster_setup"
        chef.json = SETUP_DATA
      end
    end
  end

end