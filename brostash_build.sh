#!/bin/bash
# run with: sh brostash_build

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

set -e

VERSION="0.4"
IMAGE_NAME="BroStash"
PERPARER="Binor"
PUBLISHER="Binor"

echo "Install Build Dependency"
apt-get update
apt-get -y upgrade
apt-get -y install xorriso live-build syslinux squashfs-tools python-docutils
mkdir -p $IMAGE_NAME-Live-Build

cd $IMAGE_NAME-Live-Build

lb config \
-a amd64 -d stretch \
--swap-file-size 2048 \
--chroot-filesystem squashfs \
--archive-areas "main contrib" \
--bootloader syslinux \
--debian-installer live \
--bootappend-live "boot=live swap config username=brostash \
  live-config.user-default-groups=audio,cdrom,floppy,video,dip,plugdev,scanner,\
  bluetooth,netdev,sudo" \
--iso-application Bro PF_RING Packetbeat Filebeat \
--iso-preparer $PERPARER \
--iso-publisher $PUBLISHER \
--iso-volume BrosStash $LB_CONFIG_OPTIONS

mkdir -p config/includes.chroot/etc/init.d/
mkdir -p config/includes.binary/isolinux/
mkdir -p config/includes.chroot/etc/apt/sources.list.d/
cd ..

cp data/etc/issue.net $IMAGE_NAME-Live-Build/config/includes.chroot/etc/issue.net

mkdir -p $IMAGE_NAME-Live-Build/config/includes.chroot/opt/utils/
cp data/opt/utils/README $IMAGE_NAME-Live-Build/config/includes.chroot/opt/utils/
cp data/opt/utils/iptables $IMAGE_NAME-Live-Build/config/includes.chroot/opt/utils/
cp data/opt/utils/interface-tuneup $IMAGE_NAME-Live-Build/config/includes.chroot/opt/utils/

mkdir -p $IMAGE_NAME-Live-Build/config/includes.chroot/etc/filebeat/inputs.d/
cp data/etc/filebeat/filebeat.yml $IMAGE_NAME-Live-Build/config/includes.chroot/etc/filebeat/
cp data/etc/filebeat/inputs.d/filebeat_input_bro.yml $IMAGE_NAME-Live-Build/config/includes.chroot/etc/filebeat/inputs.d/

echo "autoconf automake build-essential debian-installer-launcher live-build \
  apt-transport-https ca-certificates dirmngr gnupg openssh-server sudo" \
  >> $IMAGE_NAME-Live-Build/config/package-lists/Brostash-CoreSystem.list.chroot

echo "linux-headers-amd64 linux-image-amd64 gcc make flex bison curl \
  libssl1.0-dev zlib1g-dev swig libjemalloc-dev cmake libgoogle-perftools-dev \
  python-dev libpcap-dev g++" \
  >> $IMAGE_NAME-Live-Build/config/package-lists/Brostash-Bro.list.chroot

echo "ntp nmap lsof rsync sysstat vim htop bwm-ng dsniff ethtool openssl" \
  >> $IMAGE_NAME-Live-Build/config/package-lists/Brostash-Tools.list.chroot

cp data/chroot/brostash-inside-chroot.sh \
  $IMAGE_NAME-Live-Build/config/hooks/live/brostash-inside-chroot.hook.chroot

cp data/chroot/menues-changes.binary \
  $IMAGE_NAME-Live-Build//config/hooks/live/menues-changes.hook.binary

cp data/chroot/preseed.cfg \
  $IMAGE_NAME-Live-Build/config/includes.installer/preseed.cfg

cd $IMAGE_NAME-Live-Build
lb build 2>&1 | tee build.log
mv live-image-amd64.hybrid.iso $IMAGE_NAME-$VERSION.iso
cd ..
