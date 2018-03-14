#remove network mac and interface information
sed -i '/HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i "/^UUID/d" /etc/sysconfig/network-scripts/ifcfg-eth0

#remove any ssh keys or persistent routes, dhcp leases
rm -f /etc/ssh/ssh_host_*
rm -f /etc/udev/rules.d/70-persistent-net.rules
rm -f /var/lib/dhclient/dhclient-eth0.leases
rm -rf /tmp/*


#disable reverse dns lookups on sshd
echo "UseDNS no" >> /etc/ssh/sshd_config


#https://docs.microsoft.com/fr-fr/azure/virtual-machines/linux/create-upload-centos#centos-70
ln -s /dev/null /etc/udev/rules.d/75-persistent-net-generator.rules

#add azure repo
cat <<EOF >/etc/yum.repos.d/openlogic.repo
[openlogic]
name=CentOS-\$releasever - openlogic packages for \$basearch
baseurl=http://olcentgbl.trafficmanager.net/openlogic/\$releasever/openlogic/\$basearch/
enabled=1
gpgcheck=0
EOF

yum clean all
rm -rf /var/cache/yum
yum makecache
#TODO uncomment to update in template building
#yum -u update

#install azure agent
yum -y install python-pyasn1 WALinuxAgent
systemctl enable waagent

waagent -force -deprovision
export HISTSIZE=0

#update grub cli
sed -i -e 's/GRUB_CMDLINE_LINUX="crashkernel=auto rhgb quiet"/GRUB_CMDLINE_LINUX="crashkernel=auto rootdelay=300 console=ttyS0 earlyprintk=ttyS0 net.ifnames=0"/' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

#include hyper-v driver in initramfs
cat <<EOF >> /etc/dracut.conf
add_drivers+=" hv_vmbus "
add_drivers+=" hv_netvsc "
add_drivers+=" hv_storvsc "
EOF
dracut -f -v

