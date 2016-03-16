#!/bin/bash
# run with: sh brostash_build

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

VERSION="0.1"
IMAGE_NAME="BroStash"
PERPARER="Binor"
PUBLISHER="Binor"
LOGSTASH_REPO="deb http://packages.elasticsearch.org/logstash/2.2/debian stable main"
PF_RING_VER="6.2.0"
PF_RING_URL="http://downloads.sourceforge.net/project/ntop/PF_RING/PF_RING-$PF_RING_VER.tar.gz"
BRO_VER="2.4.1"
BRO_URL="https://www.bro.org/downloads/release/bro-$BRO_VER.tar.gz"

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
--bootappend-live "boot=live swap config username=bros live-config.user-default-groups=audio,cdrom,floppy,video,dip,plugdev,scanner,bluetooth,netdev,sudo" \
--iso-application Bro Logstash \
--iso-preparer $PERPARER \
--iso-publisher $PUBLISHER \
--iso-volume BrosStash $LB_CONFIG_OPTIONS

mkdir -p config/includes.chroot/etc/init.d/
mkdir -p config/includes.binary/isolinux/
mkdir -p config/includes.chroot/etc/apt/sources.list.d/
cd ..
echo $LOGSTASH_REPO > $IMAGE_NAME-Live-Build/config/includes.chroot/etc/apt/sources.list.d/logstash.list
echo "
autoconf automake build-essential debian-installer-launcher live-build" \
>> $IMAGE_NAME-Live-Build/config/package-lists/Brostash-CoreSystem.list.chroot

echo "
cmake make gcc gdb g++ flex bison libpcap-dev libssl-dev python-dev swig2.0 zlib1g-dev libcap-ng-dev libgeoip-dev libnuma-dev linux-headers-amd64 linux-image-amd64" \
>> $IMAGE_NAME-Live-Build/config/package-lists/Brostash-Bro.list.chroot

echo "
ntpdate iptables-persistent unattended-upgrades apt-listchanges nmap lsof munin-node rsync supervisor sysstat tcpdump tcpflow tcpreplay vim python-pip htop bwm-ng dsniff ethtool openssl" \
>> $IMAGE_NAME-Live-Build/config/package-lists/Brostash-Tools.list.chroot

echo "Generate inside chroot file"
echo "
set -e
# Add logstash key
echo \"
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v2.0.14 (GNU/Linux)

mQENBFI3HsoBCADXDtbNJnxbPqB1vDNtCsqhe49vFYsZN9IOZsZXgp7aHjh6CJBD
A+bGFOwyhbd7at35jQjWAw1O3cfYsKAmFy+Ar3LHCMkV3oZspJACTIgCrwnkic/9
CUliQe324qvObU2QRtP4Fl0zWcfb/S8UYzWXWIFuJqMvE9MaRY1bwUBvzoqavLGZ
j3SF1SPO+TB5QrHkrQHBsmX+Jda6d4Ylt8/t6CvMwgQNlrlzIO9WT+YN6zS+sqHd
1YK/aY5qhoLNhp9G/HxhcSVCkLq8SStj1ZZ1S9juBPoXV1ZWNbxFNGwOh/NYGldD
2kmBf3YgCqeLzHahsAEpvAm8TBa7Q9W21C8vABEBAAG0RUVsYXN0aWNzZWFyY2gg
KEVsYXN0aWNzZWFyY2ggU2lnbmluZyBLZXkpIDxkZXZfb3BzQGVsYXN0aWNzZWFy
Y2gub3JnPokBOAQTAQIAIgUCUjceygIbAwYLCQgHAwIGFQgCCQoLBBYCAwECHgEC
F4AACgkQ0n1mbNiOQrRzjAgAlTUQ1mgo3nK6BGXbj4XAJvuZDG0HILiUt+pPnz75
nsf0NWhqR4yGFlmpuctgCmTD+HzYtV9fp9qW/bwVuJCNtKXk3sdzYABY+Yl0Cez/
7C2GuGCOlbn0luCNT9BxJnh4mC9h/cKI3y5jvZ7wavwe41teqG14V+EoFSn3NPKm
TxcDTFrV7SmVPxCBcQze00cJhprKxkuZMPPVqpBS+JfDQtzUQD/LSFfhHj9eD+Xe
8d7sw+XvxB2aN4gnTlRzjL1nTRp0h2/IOGkqYfIG9rWmSLNlxhB2t+c0RsjdGM4/
eRlPWylFbVMc5pmDpItrkWSnzBfkmXL3vO2X3WvwmSFiQbkBDQRSNx7KAQgA5JUl
zcMW5/cuyZR8alSacKqhSbvoSqqbzHKcUQZmlzNMKGTABFG1yRx9r+wa/fvqP6OT
RzRDvVS/cycws8YX7Ddum7x8uI95b9ye1/Xy5noPEm8cD+hplnpU+PBQZJ5XJ2I+
1l9Nixx47wPGXeClLqcdn0ayd+v+Rwf3/XUJrvccG2YZUiQ4jWZkoxsA07xx7Bj+
Lt8/FKG7sHRFvePFU0ZS6JFx9GJqjSBbHRRkam+4emW3uWgVfZxuwcUCn1ayNgRt
KiFv9jQrg2TIWEvzYx9tywTCxc+FFMWAlbCzi+m4WD+QUWWfDQ009U/WM0ks0Kww
EwSk/UDuToxGnKU2dQARAQABiQEfBBgBAgAJBQJSNx7KAhsMAAoJENJ9ZmzYjkK0
c3MIAIE9hAR20mqJWLcsxLtrRs6uNF1VrpB+4n/55QU7oxA1iVBO6IFu4qgsF12J
TavnJ5MLaETlggXY+zDef9syTPXoQctpzcaNVDmedwo1SiL03uMoblOvWpMR/Y0j
6rm7IgrMWUDXDPvoPGjMl2q1iTeyHkMZEyUJ8SKsaHh4jV9wp9KmC8C+9CwMukL7
vM5w8cgvJoAwsp3Fn59AxWthN3XJYcnMfStkIuWgR7U2r+a210W6vnUxU4oN0PmM
cursYPyeV0NX/KQeUeNMwGTFB6QHS/anRaGQewijkrYYoTNtfllxIu9XYmiBERQ/
qPDlGRlOgVTd9xUfHFkzB52c70E=
=92oX
-----END PGP PUBLIC KEY BLOCK----- \" \ > logstash.key

apt-key add logstash.key
rm -f logstash.key
apt-get update

# Install logstash

apt-get install -y openjdk-7-jdk logstash
###

# Install pfring

wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCityv6-beta/GeoLiteCityv6.dat.gz
gunzip GeoLiteCity.dat.gz
gunzip GeoLiteCityv6.dat.gz
mv GeoLiteCity* /usr/share/GeoIP/.
ln -s /usr/share/GeoIP/GeoLiteCity.dat /usr/share/GeoIP/GeoIPCity.dat
ln -s /usr/share/GeoIP/GeoLiteCityv6.dat /usr/share/GeoIP/GeoIPCityv6.dat

mkdir /opt/pfring
wget $PF_RING_URL
tar -xzvf PF_RING-$PF_RING_VER.tar.gz
cd PF_RING-$PF_RING_VER/userland/lib
./configure --prefix=/opt/pfring
make
make install

cd ../libpcap
./configure --prefix=/opt/pfring
make
make install

cd ../tcpdump-*
./configure --prefix=/opt/pfring
make
make install

echo \"/opt/pfring/lib\" >> /etc/ld.so.conf

cd ../../kernel
make
make install

echo \"/opt/pfring/lib\" >> /etc/ld.so.conf

echo \"pf_ring\" >> /etc/modules

modprobe pf_ring enable_tx_capture=0 min_num_slots=65534

export LDFLAGS=\"-Wl,--no-as-needed -lrt\"

export LIBS=\"-lrt -lnuma\"

cd ../../

rm -Rf PF_RING-$PF_RING_VER*
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

echo \"
#! /bin/sh
# /etc/init.d/bro

case \\\"\\\$1\\\" in
  start)
        echo \\\"Starting script bro \\\"
        /opt/bro/bin/broctl start
        ;;
  stop)
        echo \\\"Stopping script bro\\\"
        /opt/bro/bin/broctl stop
        ;;
  *)
    echo \\\"Usage: /etc/init.d/bro {start|stop}\\\"
    exit 1
    ;;
esac
exit 0 \" \ > /etc/init.d/bro
chmod +x /etc/init.d/bro
cd ..
rm -Rf bro-$BRO_VER*

###

# Install criticalstack

wget https://intel.criticalstack.com/client/critical-stack-intel-amd64.deb
dpkg -i critical-stack-intel-amd64.deb
rm -f critical-stack-intel-amd64.deb
###

# Deploy util script

mkdir /opt/utils

echo \"
# init bro
/opt/bro/bin/broctl install

# bro cleanup cron job
echo \\\"0-59/5 * * * * root /opt/bro/bin/broctl cron\\\" >> /etc/crontab

\" \ > /opt/utils/bro_init

# Crital stasck init

echo \"
CS_INTEL_KEY=\\\"XXXXXXXXXXXXXXXXXXXXXX\\\"
critical-stack-intel api \\\$CS_INTEL_KEY
critical-stack-intel --debug api \\\$CS_INTEL_KEY
/usr/bin/critical-stack-intel config
/usr/bin/critical-stack-intel pull
/opt/bro/bin/broctl check
/opt/bro/bin/broctl install
/opt/bro/bin/broctl restart

\" \ > /opt/utils/criticalstack_init


echo \"
/usr/bin/critical-stack-intel config
echo \\\"#### Pulling feed update ####\\\"
/usr/bin/critical-stack-intel pull
echo \\\"#### Applying the updates to the bro config ####\\\"
/opt/bro/bin/broctl check
/opt/bro/bin/broctl install
echo \\\"#### Restarting bro ####\\\"
/opt/bro/bin/broctl restart
\" \ > /opt/utils/criticalstack_update

# critical stack update cron job
echo \"00 7/19 * * *  root sh /opt/utils/criticalstack_update >> /tmp/stack.out\" >> /etc/crontab

echo \"

iptables -F
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -j ACCEPT -m state --state ESTABLISHED,RELATED
iptables -A INPUT -p tcp -m multiport --dports 22,80,443,4949 -j ACCEPT
iptables -A INPUT -j LOG --log-level 4 --log-prefix \\\"[iptables_denied: \\\"
iptables -A INPUT -j DROP

iptables -A OUTPUT -j ACCEPT

iptables -A FORWARD -j DROP

iptables -L -v -n

iptables-save > /etc/iptables/rules.v4
iptables-save > /etc/iptables/rules.v6

\" \ > /opt/utils/iptables_sample

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





