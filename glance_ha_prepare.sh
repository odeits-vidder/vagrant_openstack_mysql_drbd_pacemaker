node=$(hostname)
node=$(echo $node)
echo "$node is active."


if [[ $node = "grizzly2" ]]; then


mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS glance;
GRANT ALL ON glance.* TO 'glanceUser'@'%' IDENTIFIED BY 'glancePass';
EOF

sudo cp /vagrant/glance-api-paste.ini /etc/glance/glance-api-paste.ini
sudo cp /vagrant/glance-registry-paste.ini /etc/glance/glance-registry-paste.ini
sudo cp /vagrant/glance-api.conf /etc/glance/glance-api.conf
sudo cp /vagrant/glance-registry.conf /etc/glance/glance-registry.conf
sudo cp /vagrant/glance-schema-image.json /etc/glance/schema-image.json
sudo service glance-api restart
sudo service glance-registry restart

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo cp /vagrant/glance-api-paste.ini /etc/glance/glance-api-paste.ini
sudo cp /vagrant/glance-registry-paste.ini /etc/glance/glance-registry-paste.ini
sudo cp /vagrant/glance-api.conf /etc/glance/glance-api.conf
sudo cp /vagrant/glance-registry.conf /etc/glance/glance-registry.conf
sudo cp /vagrant/glance-schema-image.json /etc/glance/schema-image.json
sudo service glance-api restart
sudo service glance-registry restart
sudo service glance-api stop
sudo service glance-registry stop
exit
EOF


sudo glance-manage db_sync

glance image-create --name myFirstImage --is-public true --container-format bare --disk-format qcow2 --location https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img

#PIDify Glance Services
sudo cp /vagrant/glance-api-service.conf /etc/init/glance-api.conf
sudo cp /vagrant/glance-registry-service.conf /etc/init/glance-registry.conf
sudo service glance-api restart
sudo service glance-registry restart

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo cp /vagrant/glance-api-service.conf /etc/init/glance-api.conf
sudo cp /vagrant/glance-registry-service.conf /etc/init/glance-registry.conf
sudo service glance-api restart
sudo service glance-registry restart
exit
EOF

# Get OpenStack Glance OCF resource agents
cd /usr/lib/ocf/resource.d
sudo mkdir -p openstack
cd openstack
sudo cp /vagrant/glance-api-ra /usr/lib/ocf/resource.d/openstack/glance-api
sudo cp /vagrant/glance-registry-ra /usr/lib/ocf/resource.d/openstack/glance-registry
sudo chmod 0755 *
cd ~

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
cd /usr/lib/ocf/resource.d
sudo mkdir -p openstack
cd openstack
sudo cp /vagrant/glance-api-ra /usr/lib/ocf/resource.d/openstack/glance-api
sudo cp /vagrant/glance-registry-ra /usr/lib/ocf/resource.d/openstack/glance-registry
sudo chmod 0755 *
cd ~
exit
EOF

#Configure Pacemaker resources
sudo crm configure primitive p_glance-api ocf:openstack:glance-api params pid="/var/run/glance/glance-api.pid" config="/etc/glance/glance-api.conf" os_password="admin_pass" os_username="admin" os_tenant_name="admin" os_auth_url="http://10.1.2.101:5000/v2.0/" op monitor interval="30s" timeout="30s"
sudo crm configure primitive p_glance-registry ocf:openstack:glance-registry params pid="/var/run/glance/glance-registry.pid" config="/etc/glance/glance-registry.conf" os_password="admin_pass" os_username="admin" os_tenant_name="admin" url="http://10.1.2.101:9191/images" keystone_get_token_url="http://10.1.2.101:5000/v2.0/tokens" op monitor interval="30s" timeout="30s"

#sudo crm configure colocation c_glance-api_on_keystone inf: p_glance-api p_keystone

#sudo crm configure order o_keystone_before_glance-api inf: p_keystone:start p_glance-api:start

#sudo crm configure colocation c_glance-registry_on_glance-api inf: p_glance-registry p_glance-api

#sudo crm configure order o_glance-api_before_glance-registry inf: p_glance-api:start p_glance-registry:start

sudo crm resource cleanup p_glance-api
sudo crm resource cleanup p_glance-registry

fi
