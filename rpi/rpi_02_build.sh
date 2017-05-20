#!/bin/bash
# HOWTO RUN: IMAGE_FILE=raspbian.img CONFIG_DIR=configdir sh rpi_02_build.sh

set -e
if [ "$(id -u)" != "0" ]
then
   echo "This script must be run as root" 1>&2
   exit
fi

if [ ! -f ${IMAGE_FILE} ]; then
  print 'Error: provided image file does not exist'
  exit
fi

apt-get update
apt-get -y upgrade
apt-get -y install qemu qemu-user-static expect
PWD=`pwd`
CHROOT_DIR=$PWD'/chroot.tmp.'`date +%Y.%m.%d.%H.%M.%S`
mkdir -p $CHROOT_DIR

init_chroot(){
  cp /usr/bin/qemu*arm* ${CHROOT_DIR}/usr/bin/
  mount -o bind /run ${CHROOT_DIR}/run
  mount -o bind /dev ${CHROOT_DIR}/dev
  mount -t devpts pts ${CHROOT_DIR}/dev/pts
  mount -t proc none ${CHROOT_DIR}/proc
  mount -t sysfs none ${CHROOT_DIR}/sys
  mount -o bind /tmp ${CHROOT_DIR}/tmp
  mv ${CHROOT_DIR}/etc/ld.so.preload ${CHROOT_DIR}/etc/ld.so.preload.bkp
  cp -pf /etc/resolv.conf ${CHROOT_DIR}/etc
  cp -pf /etc/environment ${CHROOT_DIR}/etc
}

mount_image(){
  OFFSET_BOOT_SIZE=`/sbin/fdisk -lu ${IMAGE_FILE}  | tail -n 3 | head -n 1 | awk '{ print $2 }'`
  OFFSET_ROOTFS_SIZE=`/sbin/fdisk -lu ${IMAGE_FILE} | tail -n 2 | head -n 1 | awk '{ print $2 }'`
  OFFSET_BOOT=$(($OFFSET_BOOT_SIZE * 512))
  OFFSET_ROOTFS=$(($OFFSET_ROOTFS_SIZE * 512))
  mount -o loop,offset=${OFFSET_ROOTFS} ${IMAGE_FILE} ${CHROOT_DIR}
  mount -o loop,offset=${OFFSET_BOOT} ${IMAGE_FILE} ${CHROOT_DIR}/boot
}

clean_up(){
  mv -f ${CHROOT_DIR}/etc/ld.so.preload.bkp ${CHROOT_DIR}/etc/ld.so.preload
  rm -f ${CHROOT_DIR}/etc/resolv.conf
  rm -f ${CHROOT_DIR}/etc/environment
  rm -f ${CHROOT_DIR}/usr/bin/qemu*arm*
  rm -Rf ${CHROOT_DIR}/tmp/*
  umount ${CHROOT_DIR}/dev/pts
  umount ${CHROOT_DIR}/dev
  umount ${CHROOT_DIR}/run
  umount ${CHROOT_DIR}/proc
  umount ${CHROOT_DIR}/sys
  umount ${CHROOT_DIR}/tmp
  umount ${CHROOT_DIR}/boot
  umount ${CHROOT_DIR}
  rm -Rf ${CHROOT_DIR}
}
trap clean_up EXIT TERM INT

#export QEMU_CPU=cortex-a15
export QEMU_CPU=arm1176

set -x

mount_image
init_chroot

if [ -z "$CONFIG_DIR" ]; then
  chroot ${CHROOT_DIR} /bin/bash
else
  if [ -d ${CONFIG_DIR}/files ]; then
    cp -R $CONFIG_DIR/files/* ${CHROOT_DIR}/.
  fi
  if [ -f "$CONFIG_DIR/script.sh" ]; then
    cp -pf $CONFIG_DIR/script.sh ${CHROOT_DIR}/tmp/inside_chroot.sh
    chroot ${CHROOT_DIR} /bin/bash -c "sh /tmp/inside_chroot.sh"
  else
    chroot ${CHROOT_DIR} /bin/bash
  fi
fi
