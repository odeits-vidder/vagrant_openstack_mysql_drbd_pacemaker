node=$(hostname)
node=$(echo $node)
echo "$node is active."


if [[ $node = "grizzly2" ]]; then

mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS nova;
GRANT ALL ON nova.* TO 'novaUser'@'%' IDENTIFIED BY 'novaPass'; 
EOF

sudo cp /vagrant/nova.conf /etc/nova/nova.conf
sudo cp /vagrant/nova-api-paste.ini /etc/nova/api-paste.ini
sudo cp /vagrant/nova-compute.conf /etc/nova/nova-compute.conf

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo cp /vagrant/nova.conf /etc/nova/nova.conf
sudo cp /vagrant/nova-api-paste.ini /etc/nova/api-paste.ini
sudo cp /vagrant/nova-compute.conf /etc/nova/nova-compute.conf
exit
EOF

sudo service nova-api restart
sudo service nova-cert restart
sudo service nova-compute restart
sudo service nova-conductor restart
sudo service nova-consoleauth restart
sudo service nova-novncproxy restart
sudo service nova-scheduler restart

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo service nova-api restart
sudo service nova-cert restart
sudo service nova-compute restart
sudo service nova-conductor restart
sudo service nova-consoleauth restart
sudo service nova-novncproxy restart
sudo service nova-scheduler restart
sudo service nova-api stop
sudo service nova-cert stop
sudo service nova-compute stop
sudo service nova-conductor stop
sudo service nova-consoleauth stop
sudo service nova-novncproxy stop
sudo service nova-scheduler stop
exit
EOF

sudo nova-manage db sync

#PIDify Nova Services
sudo cp /vagrant/nova-api-service.conf /etc/init/nova-api.conf
sudo cp /vagrant/nova-cert-service.conf /etc/init/nova-cert.conf
sudo cp /vagrant/nova-compute-service.conf /etc/init/nova-compute.conf
sudo cp /vagrant/nova-conductor-service.conf /etc/init/nova-conductor.conf
sudo cp /vagrant/nova-consoleauth-service.conf /etc/init/nova-consoleauth.conf
sudo cp /vagrant/nova-novncproxy-service.conf /etc/init/nova-novncproxy.conf
sudo cp /vagrant/nova-scheduler-service.conf /etc/init/nova-scheduler.conf
sudo service nova-api restart
sudo service nova-cert restart
sudo service nova-compute restart
sudo service nova-conductor restart
sudo service nova-consoleauth restart
sudo service nova-novncproxy restart
sudo service nova-scheduler restart

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo cp /vagrant/nova-api-service.conf /etc/init/nova-api.conf
sudo cp /vagrant/nova-cert-service.conf /etc/init/nova-cert.conf
sudo cp /vagrant/nova-compute-service.conf /etc/init/nova-compute.conf
sudo cp /vagrant/nova-conductor-service.conf /etc/init/nova-conductor.conf
sudo cp /vagrant/nova-consoleauth-service.conf /etc/init/nova-consoleauth.conf
sudo cp /vagrant/nova-novncproxy-service.conf /etc/init/nova-novncproxy.conf
sudo cp /vagrant/nova-scheduler-service.conf /etc/init/nova-scheduler.conf
sudo service nova-api restart
sudo service nova-cert restart
sudo service nova-compute restart
sudo service nova-conductor restart
sudo service nova-consoleauth restart
sudo service nova-novncproxy restart
sudo service nova-scheduler restart
exit
EOF

# Get OpenStack Nova OCF resource agents
cd /usr/lib/ocf/resource.d
sudo mkdir openstack
cd openstack
sudo cp /vagrant/nova-api-ra /usr/lib/ocf/resource.d/openstack/nova-api
sudo cp /vagrant/nova-cert-ra /usr/lib/ocf/resource.d/openstack/nova-cert
sudo cp /vagrant/nova-compute-ra /usr/lib/ocf/resource.d/openstack/nova-compute
sudo cp /vagrant/nova-conductor-ra /usr/lib/ocf/resource.d/openstack/nova-conductor
sudo cp /vagrant/nova-consoleauth-ra /usr/lib/ocf/resource.d/openstack/nova-consoleauth
sudo cp /vagrant/nova-novncproxy-ra /usr/lib/ocf/resource.d/openstack/nova-novncproxy
sudo cp /vagrant/nova-scheduler-ra /usr/lib/ocf/resource.d/openstack/nova-scheduler
sudo chmod 0755 *
cd ~

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
cd /usr/lib/ocf/resource.d
sudo mkdir openstack
cd openstack
sudo cp /vagrant/nova-api-ra /usr/lib/ocf/resource.d/openstack/nova-api
sudo cp /vagrant/nova-cert-ra /usr/lib/ocf/resource.d/openstack/nova-cert
sudo cp /vagrant/nova-compute-ra /usr/lib/ocf/resource.d/openstack/nova-compute
sudo cp /vagrant/nova-conductor-ra /usr/lib/ocf/resource.d/openstack/nova-conductor
sudo cp /vagrant/nova-consoleauth-ra /usr/lib/ocf/resource.d/openstack/nova-consoleauth
sudo cp /vagrant/nova-novncproxy-ra /usr/lib/ocf/resource.d/openstack/nova-novncproxy
sudo cp /vagrant/nova-scheduler-ra /usr/lib/ocf/resource.d/openstack/nova-scheduler
sudo chmod 0755 *
cd ~
exit
EOF

#Configure Pacemaker resources
sudo crm configure primitive p_nova-api ocf:openstack:nova-api params pid="/var/run/nova/nova-api.pid" config="/etc/nova/nova.conf" os_password="admin_pass" os_username="admin" os_tenant_name="admin" url="http://10.1.2.101:8774/v2/" keystone_get_token_url="http://10.1.2.101:5000/v2.0/tokens" op monitor interval="30s" timeout="30s"
sudo crm configure primitive p_nova-cert ocf:openstack:nova-cert params pid="/var/run/nova/nova-cert.pid" config="/etc/nova/nova.conf" op monitor interval="30s" timeout="30s"
sudo crm configure primitive p_nova-compute ocf:openstack:nova-compute params pid="/var/run/nova/nova-compute.pid" config="/etc/nova/nova.conf" op monitor interval="30s" timeout="30s"
sudo crm configure primitive p_nova-conductor ocf:openstack:nova-conductor params pid="/var/run/nova/nova-conductor.pid" config="/etc/nova/nova.conf" op monitor interval="30s" timeout="30s"
sudo crm configure primitive p_nova-consoleauth ocf:openstack:nova-consoleauth params pid="/var/run/nova/nova-consoleauth.pid" config="/etc/nova/nova.conf" op monitor interval="30s" timeout="30s"
sudo crm configure primitive p_nova-novncproxy ocf:openstack:nova-novncproxy params pid="/var/run/nova/nova-novncproxy.pid" config="/etc/nova/nova.conf" op monitor interval="30s" timeout="30s"
sudo crm configure primitive p_nova-scheduler ocf:openstack:nova-scheduler params pid="/var/run/nova/nova-scheduler.pid" config="/etc/nova/nova.conf" op monitor interval="30s" timeout="30s"

#sudo crm configure colocation c_keystone_on_drbd inf: p_keystone ms_drbd_mysql:Master

#sudo crm configure colocation c_keystone_not_on_slave inf: p_keystone:Stopped ms_drbd_mysql:Slave

#sudo crm configure order o_drbd_before_keystone inf: ms_drbd_mysql:promote p_keystone:start

#sudo crm configure order o_slave_before_keystone_stop inf: ms_drbd_mysql:demote p_keystone:stop

sudo crm resource cleanup p_libvirt

fi
