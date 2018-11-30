#!/bin/bash

set -e
set -x
# Add elastic repo key
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" > /etc/apt/sources.list.d/elastic-6.x.list
apt-get update

apt-get -y install linux-headers-$(uname -r)
# Install filebeat

export DEBIAN_FRONTEND=noninteractive
apt-get -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install filebeat packetbeat

# Install pfring

PF_RING_VER="7.2.0"
PF_RING_URL="https://github.com/ntop/PF_RING/archive/$PF_RING_VER.tar.gz"

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

echo "/opt/pfring/lib" >> /etc/ld.so.conf.d/pfring.conf

cd ../../kernel
make
make install

echo "pf_ring" >> /etc/modules-load.d/pfring.conf

echo "options pf_ring enable_tx_capture=0 transparent_mode=0 min_num_slots=8192" > /etc/modprobe.d/pf_ring.conf

modprobe pf_ring enable_tx_capture=0 min_num_slots=8192

export LDFLAGS="-Wl,--no-as-needed -lrt"

export LIBS="-lrt -lnuma"

ldconfig

cd ../../

rm -Rf PF_RING-$PF_RING_VER*
rm -Rf $PF_RING_VER.tar.gz
###

# Install bro

BRO_VER="2.5.5"
BRO_URL="https://www.bro.org/downloads/bro-$BRO_VER.tar.gz"

mkdir -p /opt/bro
wget $BRO_URL
tar -xvzf bro-$BRO_VER.tar.gz

cd bro-$BRO_VER
./configure --prefix=/opt/bro --with-pcap=/opt/pfring
make
make install

echo "[Unit]
Description=bro
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/opt/bro/bin/broctl start
ExecStop=/opt/bro/bin/broctl stop
Type=forking

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/bro.service

chmod +x /etc/systemd/system/bro.service

cd ..
rm -Rf bro-$BRO_VER*

echo "0-59/5 * * * * root /opt/bro/bin/broctl cron" >> /etc/crontab
echo "redef ignore_checksums = T;" >> /opt/bro/share/bro/site/local.bro

echo "brostash" > /etc/hostname

# Clean up
apt-get clean
cat /dev/null > ~/.bash_history
