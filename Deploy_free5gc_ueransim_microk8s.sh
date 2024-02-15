#!/bin/bash
user=root

git clone https://github.com/free5gc/gtp5g.git && cd gtp5g
make clean && make
sudo make install


sudo apt -y install git gcc g++ cmake autoconf libtool pkg-config libmnl-dev libyaml-dev
sudo apt-get install snapd -y
sudo snap install notes 


# If eth0 interface does not exist, we install it. Otherwise skip this step.
eth0=$(ifconfig |grep eth0)
if [ -z "$eth0" ];then
        echo "eth0 does not exist. Proceeding to its installation"	
	sudo touch /etc/systemd/network/eth0.netdev
	sudo touch /etc/systemd/network/eth0.network

	echo [NetDev] >> /etc/systemd/network/eth0.netdev
	echo Name=eth0 >> /etc/systemd/network/eth0.netdev
	echo  Kind=dummy >> /etc/systemd/network/eth0.netdev

	echo [Match] >> /etc/systemd/network/eth0.network
	echo Name=eth0 >> /etc/systemd/network/eth0.network
	echo [Network] >> /etc/systemd/network/eth0.network
	echo Address=10.100.100.100 >> /etc/systemd/network/eth0.network
	echo Mask=255.255.255.0 >> /etc/systemd/network/eth0.network

	sudo systemctl restart systemd-networkd
fi

sudo snap install microk8s --classic
echo "Switching to microk8s group..."

newgrp microk8s << EOF

echo "Now in microk8s group"
sudo usermod -a -G microk8s $user
sudo chown -f -R $user ~/.kube

sudo microk8s disable ha-cluster --force

sudo microk8s enable dns ingress dashboard storage community helm3
sudo microk8s enable multus

sudo ip link set eth0 promisc on

# Deploy the helm charts in namespace free5gc
sudo microk8s kubectl create namespace free5gc
sudo microk8s helm3 repo add towards5gs 'https://raw.githubusercontent.com/Orange-OpenSource/towards5gs-helm/main/repo/'
sudo microk8s helm3 repo update

sudo microk8s helm -n free5gc install free5gc-core towards5gs/free5gc --set global.n2network.masterIf=eth0,global.n3network.masterIf=eth0,global.n4network.masterIf=eth0,global.n6network.masterIf=eth0,global.n9network.masterIf=eth0,global.n6network.subnetIP=10.100.100.98,global.n6network.gatewayIP=10.100.100.97,global.n6network.cidr=26,free5gc-upf.upf.n6if.ipAddress=10.100.100.95,global.n2network.type=macvlan,global.n3network.type=macvlan,global.n4network.type=macvlan,global.n6network.type=macvlan,global.n9network.type=macvlan

sudo microk8s helm3 -n free5gc install free5gc-ueransim towards5gs/ueransim --set global.n2network.masterIf=eth0,global.n3network.masterIf=eth0,global.n2network.type=macvlan,global.n3network.type=macvlan

echo "Type 'watch sudo microk8s kubectl get pods -n free5gc' to see the status of the pods"
EOF
