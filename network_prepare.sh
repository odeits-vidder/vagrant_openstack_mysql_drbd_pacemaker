node=$(hostname)
node=$(echo $node)
echo "$node is active."


if [[ $node = "grizzly2" ]]; then

# Allow remote MySQL-connections
#sudo sed -i 's/127.0.0.1/10.1.2.101/g' /etc/mysql/my.cnf

#sudo service mysql stop

#sudo vgchange -an VG_PG  
#sudo drbdadm --force secondary mysql

#sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
#echo "SSH into grizzly1"
#sudo drbdadm --force primary mysql
#sudo vgchange -ay VG_PG 
#sudo sed -i 's/127.0.0.1/10.1.2.101/g' /etc/mysql/my.cnf
#sudo service mysql restart
#sudo service mysql stop
#sudo vgchange -an VG_PG  
#sudo drbdadm --force secondary mysql
#exit
#EOF

#sudo drbdadm --force primary mysql
#sudo vgchange -ay VG_PG 
#sudo service mysql restart

sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# Allow IPv4-forwarding
sudo sysctl net.ipv4.ip_forward=1

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sudo sysctl net.ipv4.ip_forward=1
exit
EOF

sudo crm resource cleanup p_mysql

sudo crm resource cleanup p_lvm_mysql

sudo /sbin/iptables -A INPUT -i eth0 -p tcp --destination-port 3306 -j ACCEPT
sudo /sbin/iptables -A INPUT -i eth0 -p tcp --destination-port 3306 -j ACCEPT

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo /sbin/iptables -A INPUT -i eth0 -p tcp --destination-port 3306 -j ACCEPT
sudo /sbin/iptables -A INPUT -i eth0 -p tcp --destination-port 3306 -j ACCEPT
exit
EOF

fi
