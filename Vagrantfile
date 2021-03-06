# -*- mode: ruby -*-
# vi: set ft=ruby :

NUM_WORKERS = 4 # number of worker nodes. NUM_NODES+1 VMs will be started.
CORES_PER_NODE = 1
MEMORY_PER_NODE = CORES_PER_NODE*1024 # MB. Total memory allocation: (NUM_WORKERS + 1) * MEMORY_PER_NODE
# Disk usage on the host is approximately (NUM_WORKERS + 1) * 5GB

SETUP_DATA = {
    'num_workers' => NUM_WORKERS,
    'cores_per_node' => CORES_PER_NODE,
    'memory_per_node' => MEMORY_PER_NODE,
    'username' => 'vagrant', # default username in the VM image
    'ubuntu_release' => 'bionic',
}

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/bionic64"

  config.vm.synced_folder "./", "/home/#{SETUP_DATA['username']}/project"

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--cpus", CORES_PER_NODE, "--memory", MEMORY_PER_NODE]
    # speed up boot: https://bugs.launchpad.net/cloud-images/+bug/1829625
    vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
    vb.customize ["modifyvm", :id, "--uartmode1", "file", File::NULL]
    #vb.gui = true
  end
  
  config.vm.define "master" do |node|
    node.vm.network "private_network", ip: "192.168.7.100"
    node.vm.network "forwarded_port", guest: 8088, host: 8088
    node.vm.network "forwarded_port", guest: 9870, host: 9870
    node.vm.hostname = "master.local"
    node.vm.provision "chef_solo" do |chef|
      chef.cookbooks_path = "."
      chef.add_recipe "cluster_setup"
      chef.json = SETUP_DATA
      chef.version = "14.12.9"
    end
  end
    
  (1..NUM_WORKERS).each do |i|
    config.vm.define "hadoop#{i}" do |node|
      node.vm.network "private_network", ip: "192.168.7." + (100+i).to_s
      node.vm.hostname = "hadoop#{i}.local"

      node.vm.provision "chef_solo" do |chef|
        chef.cookbooks_path = "."
        chef.add_recipe "cluster_setup"
        chef.json = SETUP_DATA
        chef.version = "14.12.9"
      end
    end
  end

end
