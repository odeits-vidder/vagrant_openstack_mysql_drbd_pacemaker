node=$(hostname)
node=$(echo $node)
echo "$node is active."


if [[ $node = "grizzly2" ]]; then

mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS keystone;
GRANT ALL ON keystone.* TO 'keystoneUser'@'%' IDENTIFIED BY 'keystonePass'; 
EOF


DBTRUE=$(echo $?)

sudo echo "Connection success: $DBTRUE"

sudo sed -i -e 's/connection = sqlite:\/\/\/\/var\/lib\/keystone\/keystone.db/connection = mysql:\/\/keystoneUser:keystonePass@10.1.2.101\/keystone/g' /etc/keystone/keystone.conf

# admin_token = ADMIN
sudo sed -i -e 's/\# admin_token = ADMIN/admin_token = ADMIN/g' /etc/keystone/keystone.conf
# bind_host = 0.0.0.0
sudo sed -i -e 's/\# bind_host = 0.0.0.0/bind_host = 10.1.2.101/g' /etc/keystone/keystone.conf
# public_port = 5000
sudo sed -i -e 's/\# public_port = 5000/public_port = 5000/g' /etc/keystone/keystone.conf
# admin_port = 35357
sudo sed -i -e 's/\# admin_port = 35357/admin_port = 35357/g' /etc/keystone/keystone.conf
# compute_port = 8774
sudo sed -i -e 's/\# compute_port = 8774/compute_port = 8774/g' /etc/keystone/keystone.conf
# policy_file = policy.json
sudo sed -i -e 's/\# policy_file = policy.json/policy_file = \/etc\/keystone\/policy.json/g' /etc/keystone/keystone.conf
# debug = False
sudo sed -i -e 's/\# debug = False/debug = True/g' /etc/keystone/keystone.conf
# verbose = False
sudo sed -i -e 's/\# verbose = False/verbose = True/g' /etc/keystone/keystone.conf
# log_config = logging.conf
sudo sed -i -e 's/\# log_config = logging.conf/log_config = \/etc\/keystone\/logging.conf/g' /etc/keystone/keystone.conf
# use_syslog = False
sudo sed -i -e 's/\# use_syslog = False/use_syslog = False/g' /etc/keystone/keystone.conf

sudo cp /etc/keystone/keystone.conf /vagrant/keystone.conf

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo cp /vagrant/keystone.conf /etc/keystone/keystone.conf
sudo service keystone restart
sudo service keystone stop
exit
EOF

sudo service keystone restart
sudo keystone-manage db_sync

DBTRUE=$(echo $?)

sudo echo "Connection success: $DBTRUE"

sudo cp /vagrant/keystone_basic2.sh keystone_basic.sh
sudo cp /vagrant/keystone_endpoints_basic2.sh keystone_endpoints_basic.sh

sudo chmod +x keystone_basic.sh
sudo chmod +x keystone_endpoints_basic.sh

sudo ./keystone_basic.sh
sudo ./keystone_endpoints_basic.sh

sudo touch creds
sudo chmod a+rwx creds

echo "export OS_TENANT_NAME=admin" >> creds
echo "export OS_USERNAME=admin" >> creds
echo "export OS_PASSWORD=admin_pass" >> creds
echo 'export OS_AUTH_URL="http://10.1.2.101:5000/v2.0/"'>> creds

# sudo chmod -w creds
source creds

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo touch creds
sudo chmod a+rwx creds

echo "export OS_TENANT_NAME=admin" >> creds
echo "export OS_USERNAME=admin" >> creds
echo "export OS_PASSWORD=admin_pass" >> creds
echo 'export OS_AUTH_URL="http://10.1.2.101:5000/v2.0/"'>> creds

# sudo chmod -w creds
source creds
exit
EOF

#PIDify Keystone Services
sudo cp /vagrant/keystone-service.conf /etc/init/keystone.conf
sudo service keystone restart

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo cp /vagrant/keystone-service.conf /etc/init/keystone.conf
sudo service keystone restart
exit
EOF

# Get OpenStack Keystone OCF resource agent
cd /usr/lib/ocf/resource.d
sudo mkdir -p openstack
cd openstack
sudo cp /vagrant/keystone-ra /usr/lib/ocf/resource.d/openstack/keystone
sudo chmod 0755 *
cd ~

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
cd /usr/lib/ocf/resource.d
sudo mkdir -p openstack
cd openstack
sudo cp /vagrant/keystone-ra /usr/lib/ocf/resource.d/openstack/keystone
sudo chmod 0755 *
cd ~
exit
EOF

#Configure Pacemaker resources
sudo crm configure primitive p_keystone ocf:openstack:keystone params pid="/var/run/keystone/keystone.pid" config="/etc/keystone/keystone.conf" os_password="admin_pass" os_username="admin" os_tenant_name="admin" os_auth_url="http://10.1.2.101:5000/v2.0/" op monitor interval="20s" timeout="10s" op start interval="0" timeout="120s" op stop interval="0" timeout="120s" meta target-role="Started"

#sudo crm configure colocation c_keystone_on_drbd inf: p_keystone ms_drbd_mysql:Master

#sudo crm configure colocation c_keystone_not_on_slave inf: p_keystone:Stopped ms_drbd_mysql:Slave

#sudo crm configure order o_drbd_before_keystone inf: ms_drbd_mysql:promote p_keystone:start

#sudo crm configure order o_slave_before_keystone_stop inf: ms_drbd_mysql:demote p_keystone:stop

sudo crm resource cleanup p_keystone

fi

