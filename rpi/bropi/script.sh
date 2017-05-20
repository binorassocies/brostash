#!/bin/bash
set -e
apt-get update
apt-get -y upgrade
apt-get clean all
apt-get -y install apt-transport-https iptables-persistent ntp tcpdump ethtool
apt-get clean all
apt-get -y install cmake make gcc gdb g++ flex bison libpcap-dev libssl-dev \
  python-dev swig2.0 zlib1g-dev libcap-ng-dev libgeoip-dev
apt-get clean all


# change default keyboard
sed -i 's/XKBLAYOUT="gb"/XKBLAYOUT="us"/g' /etc/default/keyboard

echo 'hdmi_force_hotplug=1' >> /boot/config.txt

echo "
 _____ _____ _____ _____ _____ _____ _____ _____
| __  | __  |     |   __|_   _|  _  |   __|  |  |
| __ -|    -|  |  |__   | | | |     |__   |     |
|_____|__|__|_____|_____| |_| |__|__|_____|__|__|

" \ > /etc/issue.net

echo "brostash" > /etc/hostname

# Clean up
apt-get clean all
cat /dev/null > ~/.bash_history
