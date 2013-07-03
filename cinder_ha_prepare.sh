node=$(hostname)
node=$(echo $node)
echo "$node is active."


if [[ $node = "grizzly2" ]]; then

mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS cinder;
GRANT ALL ON cinder.* TO 'cinderUser'@'%' IDENTIFIED BY 'cinderPass'; 
EOF

sudo cp /vagrant/cinder-api-paste.ini /etc/cinder/api-paste.ini
sudo cp /vagrant/cinder.conf /etc/cinder/cinder.conf

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo cp /vagrant/cinder-api-paste.ini /etc/cinder/api-paste.ini
sudo cp /vagrant/cinder.conf /etc/cinder/cinder.conf
exit
EOF

sudo cinder-manage db sync

sudo dd if=/dev/zero of=cinder-volumes bs=1 count=0 seek=2G
sudo losetup /dev/loop2 cinder-volumes
sudo fdisk /dev/loop2 <<EOF
n
p
1


t
8e
w
EOF

sudo partprobe /dev/loop2
sudo pvcreate /dev/loop2
sudo vgcreate cinder-volumes /dev/loop2

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo dd if=/dev/zero of=cinder-volumes bs=1 count=0 seek=2G
sudo losetup /dev/loop2 cinder-volumes
sudo fdisk /dev/loop2 <<END
n
p
1


t
8e
w
END

sudo partprobe /dev/loop2
sudo pvcreate /dev/loop2
sudo vgcreate cinder-volumes /dev/loop2
exit
EOF

#PIDify Cinder Services
sudo cp /vagrant/cinder-api-service.conf /etc/init/cinder-api.conf
sudo cp /vagrant/cinder-scheduler-service.conf /etc/init/cinder-scheduler.conf
sudo cp /vagrant/cinder-volume-service.conf /etc/init/cinder-volume.conf
sudo service cinder-api restart
sudo service cinder-scheduler restart
sudo service cinder-volume restart

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo cp /vagrant/cinder-api-service.conf /etc/init/cinder-api.conf
sudo cp /vagrant/cinder-scheduler-service.conf /etc/init/cinder-scheduler.conf
sudo cp /vagrant/cinder-volume-service.conf /etc/init/cinder-volume.conf
sudo service cinder-api restart
sudo service cinder-scheduler restart
sudo service cinder-volume restart
exit
EOF

# Get OpenStack Cinder OCF resource agents
cd /usr/lib/ocf/resource.d
sudo mkdir -p openstack
cd openstack
sudo cp /vagrant/cinder-api-ra /usr/lib/ocf/resource.d/openstack/cinder-api
sudo cp /vagrant/cinder-scheduler-ra /usr/lib/ocf/resource.d/openstack/cinder-scheduler
sudo cp /vagrant/cinder-volume-ra /usr/lib/ocf/resource.d/openstack/cinder-volume
sudo chmod 0755 *
cd ~

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
cd /usr/lib/ocf/resource.d
sudo mkdir -p openstack
cd openstack
sudo cp /vagrant/cinder-api-ra /usr/lib/ocf/resource.d/openstack/cinder-api
sudo cp /vagrant/cinder-scheduler-ra /usr/lib/ocf/resource.d/openstack/cinder-scheduler
sudo cp /vagrant/cinder-volume-ra /usr/lib/ocf/resource.d/openstack/cinder-volume
sudo chmod 0755 *
cd ~
exit
EOF

#Configure Pacemaker resources
sudo crm configure primitive p_cinder-api ocf:openstack:cinder-api params pid="/var/run/cinder/cinder-api.pid" config="/etc/cinder/cinder.conf" os_password="admin_pass" os_username="admin" os_tenant_name="admin" url="http://10.1.2.101:8776/v1/" keystone_get_token_url="http://10.1.2.101:5000/v2.0/tokens" op monitor interval="30s" timeout="30s"
sudo crm configure primitive p_cinder-scheduler ocf:openstack:cinder-scheduler params pid="/var/run/cinder/cinder-scheduler.pid" config="/etc/cinder/cinder.conf" op monitor interval="30s" timeout="30s"
sudo crm configure primitive p_cinder-volume ocf:openstack:cinder-volume params pid="/var/run/cinder/cinder-volume.pid" config="/etc/cinder/cinder.conf" op monitor interval="30s" timeout="30s"

fi
