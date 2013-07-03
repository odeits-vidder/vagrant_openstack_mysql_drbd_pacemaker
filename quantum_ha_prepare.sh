node=$(hostname)
node=$(echo $node)
echo "$node is active."


if [[ $node = "grizzly2" ]]; then


mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS quantum;
GRANT ALL ON quantum.* TO 'quantumUser'@'%' IDENTIFIED BY 'quantumPass'; 
EOF

sudo cp /vagrant/quantum-api-paste.ini /etc/quantum/api-paste.ini
sudo cp /vagrant/quantum-linuxbridge_conf.ini /etc/quantum/plugins/linuxbridge/linuxbridge_conf.ini

sudo cp /vagrant/quantum-l3_agent.ini /etc/quantum/l3_agent.ini

sudo cp /vagrant/quantum.conf /etc/quantum/quantum.conf

sudo cp /vagrant/quantum-dhcp_agent.ini /etc/quantum/dhcp_agent.ini

sudo cp /vagrant/quantum-metadata_agent.ini /etc/quantum/metadata_agent.ini

sudo cp /vagrant/quantum-plugin-dest /etc/default/quantum-server

sudo service quantum-dhcp-agent restart
sudo service quantum-l3-agent restart
sudo service quantum-metadata-agent restart
sudo service quantum-plugin-linuxbridge-agent restart
sudo service quantum-plugin-openvswitch-agent restart
sudo service quantum-server restart

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo cp /vagrant/quantum-api-paste.ini /etc/quantum/api-paste.ini
sudo cp /vagrant/quantum-linuxbridge_conf.ini /etc/quantum/plugins/linuxbridge/linuxbridge_conf.ini
sudo cp /vagrant/quantum-l3_agent.ini /etc/quantum/l3_agent.ini
sudo cp /vagrant/quantum.conf /etc/quantum/quantum.conf
sudo cp /vagrant/quantum-dhcp_agent.ini /etc/quantum/dhcp_agent.ini
sudo cp /vagrant/quantum-metadata_agent.ini /etc/quantum/metadata_agent.ini
sudo cp /vagrant/quantum-plugin-dest /etc/default/quantum-server
sudo service quantum-dhcp-agent restart
sudo service quantum-l3-agent restart
sudo service quantum-metadata-agent restart
sudo service quantum-plugin-linuxbridge-agent restart
sudo service quantum-plugin-openvswitch-agent restart
sudo service quantum-server restart
sudo service quantum-dhcp-agent stop
sudo service quantum-l3-agent stop
sudo service quantum-metadata-agent stop
sudo service quantum-plugin-linuxbridge-agent stop
sudo service quantum-plugin-openvswitch-agent stop
sudo service quantum-server stop
exit
EOF

#--Highly available dnsmasq?

PROCESS=$(echo $(sudo netstat -nap | grep ^tcp | grep :53 | awk '{printf("%s\n", substr($7, 1, index($7, "/") - 1))}'))
sudo kill $PROCESS
sudo service dnsmasq restart

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo service dnsmasq restart
exit
EOF

#PIDify Quantum Services
sudo cp /vagrant/quantum-server-service.conf /etc/init/quantum-server.conf
sudo cp /vagrant/quantum-plugin-linuxbridge-agent-service.conf /etc/init/quantum-plugin-linuxbridge-agent.conf
sudo cp /vagrant/quantum-l3-agent-service.conf /etc/init/quantum-l3-agent.conf
sudo cp /vagrant/quantum-metadata-agent-service.conf /etc/init/quantum-metadata-agent.conf
sudo cp /vagrant/quantum-dhcp-agent-service.conf /etc/init/quantum-dhcp-agent.conf
sudo service quantum-server restart
sudo service quantum-plugin-linuxbridge-agent restart
sudo service quantum-l3-agent restart
sudo service quantum-metadata-agent restart
sudo service quantum-dhcp-agent restart

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo cp /vagrant/quantum-server-service.conf /etc/init/quantum-server.conf
sudo cp /vagrant/quantum-plugin-linuxbridge-agent-service.conf /etc/init/quantum-plugin-linuxbridge-agent.conf
sudo cp /vagrant/quantum-l3-agent-service.conf /etc/init/quantum-l3-agent.conf
sudo cp /vagrant/quantum-metadata-agent-service.conf /etc/init/quantum-metadata-agent.conf
sudo cp /vagrant/quantum-dhcp-agent-service.conf /etc/init/quantum-dhcp-agent.conf
sudo service quantum-server restart
sudo service quantum-plugin-linuxbridge-agent restart
sudo service quantum-l3-agent restart
sudo service quantum-metadata-agent restart
sudo service quantum-dhcp-agent restart
exit
EOF


# Get OpenStack Quantum OCF resource agents
cd /usr/lib/ocf/resource.d
sudo mkdir -p openstack
cd openstack
sudo cp /vagrant/quantum-server-ra /usr/lib/ocf/resource.d/openstack/quantum-server
sudo cp /vagrant/quantum-linuxbridge-plugin-ra /usr/lib/ocf/resource.d/openstack/quantum-plugin-linuxbridge-agent
sudo cp /vagrant/quantum-dhcp-agent-ra /usr/lib/ocf/resource.d/openstack/quantum-dhcp-agent
sudo cp /vagrant/quantum-l3-agent-ra /usr/lib/ocf/resource.d/openstack/quantum-l3-agent
sudo cp /vagrant/quantum-metadata-agent-ra /usr/lib/ocf/resource.d/openstack/quantum-metadata-agent
sudo chmod 0755 *
cd ~

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
cd /usr/lib/ocf/resource.d
sudo mkdir -p openstack
cd openstack
sudo cp /vagrant/quantum-server-ra /usr/lib/ocf/resource.d/openstack/quantum-server
sudo cp /vagrant/quantum-linuxbridge-plugin-ra /usr/lib/ocf/resource.d/openstack/quantum-plugin-linuxbridge-agent
sudo cp /vagrant/quantum-dhcp-agent-ra /usr/lib/ocf/resource.d/openstack/quantum-dhcp-agent
sudo cp /vagrant/quantum-l3-agent-ra /usr/lib/ocf/resource.d/openstack/quantum-l3-agent
sudo cp /vagrant/quantum-metadata-agent-ra /usr/lib/ocf/resource.d/openstack/quantum-metadata-agent
sudo chmod 0755 *
cd ~
exit
EOF

#Configure Pacemaker resources
sudo crm configure primitive p_quantum-server ocf:openstack:quantum-server params pid="/var/run/quantum/quantum-server.pid" config="/etc/quantum/quantum.conf" os_password="admin_pass" os_username="admin" os_tenant_name="admin" url="http://10.1.2.101" keystone_get_token_url="http://10.1.2.101:5000/v2.0/tokens" op monitor interval="30s" timeout="30s"
sudo crm configure primitive p_quantum-plugin-linuxbridge-agent ocf:openstack:quantum-plugin-linuxbridge-agent params pid="/var/run/quantum/quantum-plugin-linuxbridge-agent.pid" config="/etc/quantum/quantum.conf" os_password="admin_pass" os_username="admin" os_tenant_name="admin" url="http://10.1.2.101" keystone_get_token_url="http://10.1.2.101:5000/v2.0/tokens" op monitor interval="30s" timeout="30s"
sudo crm configure primitive p_quantum-metadata-agent ocf:openstack:quantum-metadata-agent params pid="/var/run/quantum/quantum-metadata-agent.pid" agent_config="/etc/quantum/metadata_agent.ini" config="/etc/quantum/quantum.conf" op monitor interval="30s" timeout="30s"
sudo crm configure primitive p_quantum-l3-agent ocf:openstack:quantum-l3-agent params pid="/var/run/quantum/quantum-l3-agent.pid" plugin_config="/etc/quantum/l3_agent.ini" config="/etc/quantum/quantum.conf" op monitor interval="30s" timeout="30s"
sudo crm configure primitive p_quantum-dhcp-agent ocf:openstack:quantum-dhcp-agent params pid="/var/run/quantum/quantum-dhcp-agent.pid" plugin_config="/etc/quantum/dhcp_agent.ini" config="/etc/quantum/quantum.conf" op monitor interval="30s" timeout="30s"

sudo crm resource cleanup p_quantum-plugin-linuxbridge-agent
#sudo crm configure colocation c_quantum-server_on_keystone inf: p_quantum-server p_keystone

#sudo crm configure order o_keystone_before_quantum-server inf: p_keystone:start p_quantum-server:start

fi
