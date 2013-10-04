#!/bin/bash

sudo apt-get update
sudo apt-get install libconfig-general-perl libibverbs1 librdmacm1 libsgutils2-2 sg3-utils tgt -y
sudo apt-get install cinder-volume -y
#sudo apt-get upgrade -y
#sudo apt-get dist-upgrade -y
sudo apt-get update
#DEBIAN_FRONTEND=noninteractive sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy upgrade

#DEBIAN_FRONTEND=noninteractive sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy dist-upgrade

sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# Allow IPv4-forwarding
sysctl net.ipv4.ip_forward=1
