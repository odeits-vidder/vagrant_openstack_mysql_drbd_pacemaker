node=$(hostname)
node=$(echo $node)
echo "$node is active."


if [[ $node = "grizzly2" ]]; then

sudo cp /vagrant/qemu.conf /etc/libvirt/qemu.conf
sudo virsh net-destroy default
sudo virsh net-undefine default
sudo cp /vagrant/libvirtd.conf /etc/libvirt/libvirtd.conf
sudo cp /vagrant/libvirt-bin.conf /etc/init/libvirt-bin.conf
sudo cp /vagrant/libvirt-bin /etc/default/libvirt-bin

sudo service libvirt-bin restart

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo cp /vagrant/qemu.conf /etc/libvirt/qemu.conf
sudo virsh net-destroy default
sudo virsh net-undefine default
sudo cp /vagrant/libvirtd.conf /etc/libvirt/libvirtd.conf
sudo cp /vagrant/libvirt-bin.conf /etc/init/libvirt-bin.conf
sudo cp /vagrant/libvirt-bin /etc/default/libvirt-bin
sudo service libvirt-bin restart
exit
EOF

# Get OpenStack Libvirt OCF resource agent
cd /usr/lib/ocf/resource.d
sudo mkdir -p openstack
cd openstack
sudo cp /vagrant/libvirt-ra /usr/lib/ocf/resource.d/openstack/libvirt
sudo chmod 0755 *
cd ~

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
cd /usr/lib/ocf/resource.d
sudo mkdir -p openstack
cd openstack
sudo cp /vagrant/libvirt-ra /usr/lib/ocf/resource.d/openstack/libvirt
sudo chmod 0755 *
cd ~
exit
EOF

#Configure Pacemaker resources
sudo crm configure primitive p_libvirt ocf:openstack:libvirt params pid="/var/run/libvirtd.pid" config="/etc/libvirt/libvirtd.conf" op monitor interval="20s" timeout="10s" op start interval="0" timeout="120s" op stop interval="0" timeout="120s" meta target-role="Started"

#sudo crm configure colocation c_keystone_on_drbd inf: p_keystone ms_drbd_mysql:Master

#sudo crm configure colocation c_keystone_not_on_slave inf: p_keystone:Stopped ms_drbd_mysql:Slave

#sudo crm configure order o_drbd_before_keystone inf: ms_drbd_mysql:promote p_keystone:start

#sudo crm configure order o_slave_before_keystone_stop inf: ms_drbd_mysql:demote p_keystone:stop

sudo crm resource cleanup p_libvirt

fi
