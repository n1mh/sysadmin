#!/bin/bash

# Diego Martínez Castañeda <n1mh@n1mh.org>
# Based on Jerry Gamblin's idea:
# http://jerrygamblin.com/2016/07/13/my-first-10-seconds-on-a-server/

# Script should be executed by root. It installs and configures sudo, although.
# This script should be obsolete as soon as I learn Ansible :)

# Get the script
# curl -sSL https://raw.githubusercontent.com/n1mh/sysadmin/master/first_steps.sh | sh

PATH=/bin:/usr/bin:/sbin:/usr/sbin

if [ $UID ] ; then
	echo "You need to be root to run this script..."
	exit 1
fi

# root password
passwd

# firewall
apt-get install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
sed -i 's/ENABLED=no/ENABLED=yes/g' /etc/ufw/ufw.conf
chmod 0644 ~/ufw.conf

# timezone
timedatectl set-timezone Europe/Madrid

# upgrade system
apt-get update && apt-get -y dist-upgrade

# install packages
apt-get install -y fail2ban sudo
#apt-get install -y git unattended-upgrades

# new user
useradd jonsnow
passwd jonsnow
mkdir /home/jonsnow
chmod -R 700 /home/jonsnow
chown -R jonsnow:jonsnow /home/jonsnow

# configure sudo
usermod -a -G sudo jonsnow
sed -i 's/%sudo   ALL=(ALL:ALL) ALL/%sudo   ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
chmod 440 /etc/sudoers

# little setup for ssh
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
echo "DebianBanner no" >> /etc/ssh/sshd_config
echo "AllowUsers jonsnow" >> /etc/ssh/sshd_config
echo "MaxStartups 1" >> /etc/ssh/sshd_config
echo "MaxAuthTries 2" >> /etc/ssh/sshd_config
service ssh restart

# successfully exit
exit 0
