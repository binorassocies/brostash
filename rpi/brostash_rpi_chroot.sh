LOGSTASH_REPO="deb http://packages.elasticsearch.org/logstash/2.2/debian stable main"
BRO_VER="2.4.1"
BRO_URL="https://www.bro.org/downloads/release/bro-$BRO_VER.tar.gz"

apt-get update
apt-get -y upgrade
apt-get -y install ntpdate iptables-persistent unattended-upgrades apt-listchanges nmap lsof munin-node rsync supervisor sysstat tcpdump tcpflow tcpreplay vim python-pip htop bwm-ng dsniff ethtool

apt-get -y install cmake make gcc gdb g++ flex bison libpcap-dev libssl-dev python-dev swig2.0 zlib1g-dev libcap-ng-dev libgeoip-dev

# Install bro

wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCityv6-beta/GeoLiteCityv6.dat.gz
gunzip GeoLiteCity.dat.gz
gunzip GeoLiteCityv6.dat.gz
mv GeoLiteCity* /usr/share/GeoIP/.
ln -s /usr/share/GeoIP/GeoLiteCity.dat /usr/share/GeoIP/GeoIPCity.dat
ln -s /usr/share/GeoIP/GeoLiteCityv6.dat /usr/share/GeoIP/GeoIPCityv6.dat

mkdir -p /opt/bro
wget $BRO_URL
tar -xvzf bro-$BRO_VER.tar.gz

cd bro-*
./configure --prefix=/opt/bro
make
make install

echo "export PATH=/opt/bro/bin:/opt/pfring/bin:/opt/pfring/sbin:\$PATH" >> /etc/profile

echo "
#! /bin/sh
# /etc/init.d/bro

case \"\$1\" in
  start)
        echo \"Starting script bro \"
        /opt/bro/bin/broctl start
        ;;
  stop)
        echo \"Stopping script bro\"
        /opt/bro/bin/broctl stop
        ;;
  *)
    echo \"Usage: /etc/init.d/bro {start|stop}\"
    exit 1
    ;;
esac
exit 0 " \ > /etc/init.d/bro
chmod +x /etc/init.d/bro
cd ..
rm -Rf bro-$BRO_VER*

wget https://intel.criticalstack.com/client/critical-stack-intel-arm.deb
dpkg -i critical-stack-intel-arm.deb
rm -f critical-stack-intel-arm.deb

mkdir /opt/utils

echo "
# init bro
/opt/bro/bin/broctl install

# bro cleanup cron job
echo \"0-59/5 * * * * root /opt/bro/bin/broctl cron\" >> /etc/crontab

" \ > /opt/utils/bro_init

# Crital stasck init

echo "
CS_INTEL_KEY=\"XXXXXXXXXXXXXXXXXXXXXX\"
critical-stack-intel api \$CS_INTEL_KEY
critical-stack-intel --debug api \$CS_INTEL_KEY
/usr/bin/critical-stack-intel config
/usr/bin/critical-stack-intel pull
/opt/bro/bin/broctl check
/opt/bro/bin/broctl install
/opt/bro/bin/broctl restart

" \ > /opt/utils/criticalstack_init

echo "
/usr/bin/critical-stack-intel config
echo \"#### Pulling feed update ####\"
/usr/bin/critical-stack-intel pull
echo \"#### Applying the updates to the bro config ####\"
/opt/bro/bin/broctl check
/opt/bro/bin/broctl install
echo \"#### Restarting bro ####\"
/opt/bro/bin/broctl restart
" \ > /opt/utils/criticalstack_update

# critical stack update cron job
echo "00 7/19 * * *  root sh /opt/utils/criticalstack_update >> /tmp/stack.out" >> /etc/crontab


echo "

iptables -F
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -j ACCEPT -m state --state ESTABLISHED,RELATED
iptables -A INPUT -p tcp -m multiport --dports 22,80,443,4949 -j ACCEPT
iptables -A INPUT -j LOG --log-level 4 --log-prefix \"[iptables_denied: \"
iptables -A INPUT -j DROP

iptables -A OUTPUT -j ACCEPT

iptables -A FORWARD -j DROP

iptables -L -v -n

iptables-save > /etc/iptables/rules.v4
iptables-save > /etc/iptables/rules.v6

" \ > /opt/utils/iptables_sample

# NIC tunning

echo "
#!/bin/bash

/sbin/ethtool -G \$IFACE rx 4096 >/dev/null 2>&1 ;
for i in rx tx sg tso ufo gso gro lro rxvlan txvlan; do /sbin/ethtool -K \$IFACE \$i off >/dev/null 2>&1; done;

/sbin/ethtool -N \$IFACE rx-flow-hash udp4 sdfn >/dev/null 2>&1;
/sbin/ethtool -N \$IFACE rx-flow-hash udp6 sdfn >/dev/null 2>&1;
/sbin/ethtool -C \$IFACE rx-usecs 1 rx-frames 0 >/dev/null 2>&1;
/sbin/ethtool -C \$IFACE adaptive-rx off >/dev/null 2>&1;

exit 0
" \ >  /etc/network/if-up.d/interface-tuneup

chmod +x /etc/network/if-up.d/interface-tuneup

echo "                                                 
 _____ _____ _____ _____ _____ _____ _____ _____ 
| __  | __  |     |   __|_   _|  _  |   __|  |  |
| __ -|    -|  |  |__   | | | |     |__   |     |
|_____|__|__|_____|_____| |_| |__|__|_____|__|__|
                                                                                                 
" \ > /etc/issue.net

echo "brostash" > /etc/hostname

# Clean up
apt-get clean
cat /dev/null > ~/.bash_history
