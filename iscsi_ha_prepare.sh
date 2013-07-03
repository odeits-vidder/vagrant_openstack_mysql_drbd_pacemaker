node=$(hostname)
node=$(echo $node)
echo "$node is active."


if [[ $node = "grizzly2" ]]; then


sudo cp /vagrant/iscsitarget /etc/default/iscsitarget

sudo apt-get install -y linux-headers-$(uname -r)

sudo service iscsitarget start
sudo service open-iscsi start


sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo cp /vagrant/iscsitarget /etc/default/iscsitarget

sudo apt-get install -y linux-headers-$(uname -r)

sudo service iscsitarget start
sudo service open-iscsi start
exit
EOF

# Get iSCSI OCF resource agents
sudo cp /vagrant/iscsi-ra /usr/lib/ocf/resource.d/openstack/iscsi

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo cp /vagrant/iscsi-ra /usr/lib/ocf/resource.d/openstack/iscsi
exit
EOF

#Configure Pacemaker resources
sudo crm configure primitive p_iscsi ocf:openstack:iscsi params pid="/var/run/iscsid.pid" config="/etc/default/iscsitarget" os_password="admin_pass" os_username="admin" os_tenant_name="admin" op monitor interval="30s" timeout="30s"

#sudo crm configure primitive p_ietd ocf:openstack:ietdserv params pid="/var/run/ietd.pid" config="/etc/default/iscsitarget" os_password="admin_pass" os_username="admin" os_tenant_name="admin" op monitor interval="30s" timeout="30s"

fi
