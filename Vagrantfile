# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "debian/bookworm64"

    config.vm.define "serverDB1" do |serverDB1|
      serverDB1.vm.hostname = "serverDB1"
      serverDB1.vm.network "private_network", ip: "192.168.30.40", virtualbox__intnet: "red_bd"
      # serverDB1.vm.provision "shell", path: "server_db.sh"
    end

    config.vm.define "serverDB2" do |serverDB2|
      serverDB2.vm.hostname = "serverDB2"
      serverDB2.vm.network "private_network", ip: "192.168.30.50", virtualbox__intnet: "red_bd"
      # serverDB2.vm.provision "shell", path: "server_db.sh"
    end

    config.vm.define "proxyDB" do |proxyDB|
      proxyDB.vm.hostname = "proxyDB"
      proxyDB.vm.network "private_network", ip: "192.168.30.5", virtualbox__intnet: "red_bd"
      proxyDB.vm.network "private_network", ip: "192.168.20.5", virtualbox__intnet: "red_cluster"
      # proxyDB.vm.provision "shell", path: "proxyDB.sh"
    end

    config.vm.define "serverNFS" do |serverNFS|
      serverNFS.vm.hostname = "serverNFS"
      serverNFS.vm.network "private_network", ip: "192.168.10.30", virtualbox__intnet: "red_www"
      serverNFS.vm.network "private_network", ip: "192.168.20.30", virtualbox__intnet: "red_cluster"
      # serverNFS.vm.provision "shell", path: "server_nfs.sh"
    end
    
    config.vm.define "server1" do |server1|
      server1.vm.hostname = "server1"
      server1.vm.network "private_network", ip: "192.168.10.10", virtualbox__intnet: "red_www"
      server1.vm.network "private_network", ip: "192.168.20.10", virtualbox__intnet: "red_cluster"
      # server1.vm.provision "shell", path: "server_web.sh"
    end

    config.vm.define "server2" do |server2|
      server2.vm.hostname = "server2"
      server2.vm.network "private_network", ip: "192.168.10.20", virtualbox__intnet: "red_www"
      server2.vm.network "private_network", ip: "192.168.20.20", virtualbox__intnet: "red_cluster"
      # server2.vm.provision "shell", path: "server_web.sh"
    end

    config.vm.define "balanceador" do |balanceador|
      balanceador.vm.hostname = "balanceador"
      balanceador.vm.network "private_network", ip: "192.168.10.5", virtualbox__intnet: "red_www"
      balanceador.vm.network "forwarded_port", guest: 80, host: 8080
      balanceador.vm.network "forwarded_port", guest: 443, host: 8443
      # balanceador.vm.provision "shell", path: "balanceador.sh"
    end

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Disable the default share of the current code directory. Doing this
  # provides improved isolation between the vagrant box and your host
  # by making sure your Vagrantfile isn't accessible to the vagrant box.
  # If you use this you may want to enable additional shared subfolders as
  # shown above.
  # config.vm.synced_folder ".", "/vagrant", disabled: true

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Ansible, Chef, Docker, Puppet and Salt are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get update
  #   apt-get install -y apache2
  # SHELL
end
