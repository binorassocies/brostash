#!/bin/bash
# run with: sh brostash_build

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

set -e

VERSION="0.2"
IMAGE_NAME="BroStash"
PERPARER="Binor"
PUBLISHER="Binor"
LOGSTASH_REPO="deb https://artifacts.elastic.co/packages/5.x/apt stable main"
PF_RING_VER="6.6.0"
PF_RING_URL="https://github.com/ntop/PF_RING/archive/$PF_RING_VER.tar.gz"

BRO_VER="2.5.2"
BRO_URL="https://www.bro.org/downloads/bro-$BRO_VER.tar.gz"

echo "Install Dependency"
apt-get update
apt-get -y upgrade
apt-get -y install xorriso live-build syslinux squashfs-tools python-docutils
mkdir -p $IMAGE_NAME-Live-Build

cd $IMAGE_NAME-Live-Build

lb config \
-a amd64 -d jessie \
--swap-file-size 2048 \
--chroot-filesystem squashfs \
--archive-areas "main contrib" \
--bootloader syslinux \
--debian-installer live \
--bootappend-live "boot=live swap config username=bros \
  live-config.user-default-groups=audio,cdrom,floppy,video,dip,plugdev,scanner,\
  bluetooth,netdev,sudo" \
--iso-application Bro PF_RING Filebeat \
--iso-preparer $PERPARER \
--iso-publisher $PUBLISHER \
--iso-volume BrosStash $LB_CONFIG_OPTIONS

mkdir -p config/includes.chroot/etc/init.d/
mkdir -p config/includes.binary/isolinux/
mkdir -p config/includes.chroot/etc/apt/sources.list.d/
cd ..
echo $LOGSTASH_REPO > $IMAGE_NAME-Live-Build/config/includes.chroot/etc/apt/sources.list.d/logstash.list
echo "autoconf automake build-essential debian-installer-launcher live-build \
  apt-transport-https" \
  >> $IMAGE_NAME-Live-Build/config/package-lists/Brostash-CoreSystem.list.chroot

echo "cmake make gcc gdb g++ flex bison libpcap-dev libssl-dev python-dev \
  swig2.0 zlib1g-dev libcap-ng-dev libgeoip-dev libnuma-dev \
  linux-headers-amd64 linux-image-amd64" \
  >> $IMAGE_NAME-Live-Build/config/package-lists/Brostash-Bro.list.chroot

echo "ntp iptables-persistent nmap lsof rsync sysstat vim python-pip htop \
  bwm-ng dsniff ethtool openssl" \
  >> $IMAGE_NAME-Live-Build/config/package-lists/Brostash-Tools.list.chroot

echo "Generate inside chroot file"
echo "
set -e
# Add logstash key
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
apt-get update

# Install filebeat

apt-get install -y filebeat
###

# Install pfring

mkdir /opt/pfring
wget $PF_RING_URL
tar -xzvf $PF_RING_VER.tar.gz
cd PF_RING-$PF_RING_VER/userland/lib
./configure --prefix=/opt/pfring
make
make install

cd ../libpcap
./configure --prefix=/opt/pfring
make
make install

cd ../tcpdump
./configure --prefix=/opt/pfring
make
make install

echo \"/opt/pfring/lib\" >> /etc/ld.so.conf.d/pfring.conf

cd ../../kernel
make
make install

echo \"pf_ring\" >> /etc/modules-load.d/pfring.conf

echo \"options pf_ring enable_tx_capture=0 transparent_mode=0 min_num_slots=65534\" > /etc/modprobe.d/pf_ring.conf

modprobe pf_ring enable_tx_capture=0 min_num_slots=65534

export LDFLAGS=\"-Wl,--no-as-needed -lrt\"

export LIBS=\"-lrt -lnuma\"

ldconfig

cd ../../

rm -Rf PF_RING-$PF_RING_VER*
rm -Rf $PF_RING_VER.tar.gz
###

# Install bro

mkdir -p /opt/bro
wget $BRO_URL
tar -xvzf bro-$BRO_VER.tar.gz

cd bro-*
./configure --prefix=/opt/bro --with-pcap=/opt/pfring
make
make install

echo \"export PATH=/opt/bro/bin:/opt/pfring/bin:/opt/pfring/sbin:\\\$PATH\" >> /etc/profile

echo \"[Unit]
Description=bro
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/opt/bro/bin/broctl start
ExecStop=/opt/bro/bin/broctl stop
Type=forking

[Install]
WantedBy=multi-user.target\" > /etc/systemd/system/bro.service

chmod +x /etc/systemd/system/bro.service

cd ..
rm -Rf bro-$BRO_VER*

# NIC tunning

echo \"
#!/bin/bash

/sbin/ethtool -G \\\$IFACE rx 4096 >/dev/null 2>&1 ;
for i in rx tx sg tso ufo gso gro lro rxvlan txvlan; do /sbin/ethtool -K \\\$IFACE \\\$i off >/dev/null 2>&1; done;

/sbin/ethtool -N \\\$IFACE rx-flow-hash udp4 sdfn >/dev/null 2>&1;
/sbin/ethtool -N \\\$IFACE rx-flow-hash udp6 sdfn >/dev/null 2>&1;
/sbin/ethtool -C \\\$IFACE rx-usecs 1 rx-frames 0 >/dev/null 2>&1;
/sbin/ethtool -C \\\$IFACE adaptive-rx off >/dev/null 2>&1;

exit 0
\" \ >  /etc/network/if-up.d/interface-tuneup

chmod +x /etc/network/if-up.d/interface-tuneup

###

mkdir /opt/utils

echo \"
# init bro
/opt/bro/bin/broctl install

# bro cleanup cron job
echo \\\"0-59/5 * * * * root /opt/bro/bin/broctl cron\\\" >> /etc/crontab
echo \\\"redef ignore_checksums = T;\\\" >> /opt/bro/share/bro/site/local.bro

iptables -F
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -j ACCEPT -m state --state ESTABLISHED,RELATED
iptables -A INPUT -p tcp -m multiport --dports 22,80,443 -j ACCEPT
iptables -A INPUT -j DROP

iptables -A OUTPUT -j ACCEPT

iptables -A FORWARD -j DROP

iptables -L -v -n

iptables-save > /etc/iptables/rules.v4
iptables-save > /etc/iptables/rules.v6

\" \ > /opt/utils/bro_init

echo \"
 _____ _____ _____ _____ _____ _____ _____ _____
| __  | __  |     |   __|_   _|  _  |   __|  |  |
| __ -|    -|  |  |__   | | | |     |__   |     |
|_____|__|__|_____|_____| |_| |__|__|_____|__|__|

\" \ > /etc/issue.net

echo \"brostash\" > /etc/hostname

# Clean up
apt-get clean
cat /dev/null > ~/.bash_history

" \ > $IMAGE_NAME-Live-Build/config/hooks/chroot-inside-Debian-Live.chroot

echo "
sed -i -e 's|menu label \^Live|menu label \^$IMAGE_NAME Live|' binary/isolinux/live.cfg
sed -i -e 's|menu label \^Install|menu label \^$IMAGE_NAME Install|' binary/isolinux/install.cfg
sed -i -e 's|menu label \^Graphical install|menu label \^$IMAGE_NAME Graphical install|' binary/isolinux/install.cfg " \ > $IMAGE_NAME-Live-Build/config/hooks/menues-changes.binary

echo "
d-i netcfg/get_hostname string $IMAGE_NAME
d-i passwd/user-fullname string bros User
d-i passwd/username string bros
d-i debian-installer/locale string en_US.UTF-8
d-i passwd/user-password password live
d-i passwd/user-password-again password live
d-i passwd/user-default-groups string audio cdrom floppy video dip plugdev scanner bluetooth netdev sudo
d-i passwd/root-password password live69
d-i passwd/root-password-again password live69
" > $IMAGE_NAME-Live-Build/config/includes.installer/preseed.cfg

cd $IMAGE_NAME-Live-Build
lb build 2>&1 | tee build.log
mv live-image-amd64.hybrid.iso $IMAGE_NAME-$VERSION.iso
cd ..
