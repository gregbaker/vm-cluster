A simple virtual machine Hadoop cluster to experiment with.

There are some configuration variables at the top of the `Vagrantfile` which you can set to control the size of your virtual cluster. Edit those before you start the virtual machines, and make sure everything can actually be handled by your host machine.

Once that's done, make sure you have Vagrant and VirtualBox installed and:
```
vagrant plugin install vagrant-berkshelf
vagrant up
```


You can then connect to the cluster nodes, likely the master with the command:
```
vagrant ssh master
```

There are a few convenience scripts to help you start/stop things:
```
dfs-format
start-all
stop-all
```