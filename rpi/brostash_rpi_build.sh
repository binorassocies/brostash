#!/bin/bash
# run with: sh brostash_rpi_build
apt-get update
apt-get -y upgrade
apt-get -y install qemu qemu-user-static expect unzip

if [ "$(id -u)" != "0" ]
then
   echo "This script must be run as root" 1>&2
   exit 1
fi

SIZE=0
case $1 in
   (*[!0-9]*|'') SIZE=0;;
   (*)           SIZE=$1;;
esac

set -e
set -x
CHR_DIR_PATH='/opt/brostash_rpi'
CHR_SCRIPT='./brostash_rpi_chroot.sh'
IMAGE='2016-02-26-raspbian-jessie-lite.img'
OFFSET_ROOTFS=$((131072 * 512)) 
OFFSET_BOOT=$((8192 * 512))
NEW_IMAGE_SIZE=$(($SIZE * 1024))

clean_up(){
    mv ${CHR_DIR_PATH}/etc/ld.so.preload.bkp ${CHR_DIR_PATH}/etc/ld.so.preload
    rm ${CHR_DIR_PATH}/etc/resolv.conf
    rm ${CHR_DIR_PATH}/usr/bin/qemu*arm*
    rm ${CHR_DIR_PATH}/tmp/*
    umount ${CHR_DIR_PATH}/dev/pts
    umount ${CHR_DIR_PATH}/dev
    umount ${CHR_DIR_PATH}/run
    umount ${CHR_DIR_PATH}/proc
    umount ${CHR_DIR_PATH}/sys
    umount ${CHR_DIR_PATH}/tmp
    umount ${CHR_DIR_PATH}/boot
    umount ${CHR_DIR_PATH}

    rm -Rf ${CHR_DIR_PATH}
}
trap clean_up EXIT TERM INT

resize_img(){
    dd if=/dev/zero bs=1024k count=$NEW_IMAGE_SIZE >> $IMAGE
    losetup -f --show $IMAGE
    losetup -f --show -o ${OFFSET_ROOTFS} $IMAGE
    echo "Please use the following commands inside the fdisk prompt: "
    echo "1: **p** to list the partions and take note of"
    echo "       the second partion first sector."
    echo "2: **d** to delete a partion"
    echo "3: **2** to select the partition to delete"
    echo "4: **n** to create a new partion"
    echo "5: **p** to create a new primary partion"
    echo "6: **2** to select the new partion number"
    echo "7: **First sector** put here the number noted in the first step!"
    echo "8: **Last sector** keep the default value!"
    echo "9: **w** to write the changes"
    fdisk $IMAGE

    echo "Check the image file system"
    e2fsck -f /dev/loop1
    resize2fs /dev/loop1
    echo "Cleaning up"
    losetup -d /dev/loop0 /dev/loop1
}

if [ $SIZE -gt 0 ] ; then
    echo "Resizing the image"
    resize_img
fi

export QEMU_CPU=arm1176
mkdir -p $CHR_DIR_PATH

if [ -f ${IMAGE} ]; then
    mount -o loop,offset=${OFFSET_ROOTFS} ${IMAGE} ${CHR_DIR_PATH}
    mount -o loop,offset=${OFFSET_BOOT} ${IMAGE} ${CHR_DIR_PATH}/boot
else
    print 'Error: provided image file does not exist'
    exit
fi

cp /usr/bin/qemu*arm* ${CHR_DIR_PATH}/usr/bin/
mount -o bind /run ${CHR_DIR_PATH}/run
mount -o bind /dev ${CHR_DIR_PATH}/dev
mount -t devpts pts ${CHR_DIR_PATH}/dev/pts
mount -t proc none ${CHR_DIR_PATH}/proc
mount -t sysfs none ${CHR_DIR_PATH}/sys
mount -o bind /tmp ${CHR_DIR_PATH}/tmp
mv ${CHR_DIR_PATH}/etc/ld.so.preload ${CHR_DIR_PATH}/etc/ld.so.preload.bkp
cp -pf /etc/resolv.conf ${CHR_DIR_PATH}/etc
cp -pf $CHR_SCRIPT ${CHR_DIR_PATH}/tmp/inside_chroot.sh

chroot ${CHR_DIR_PATH} /bin/bash -c "sh /tmp/inside_chroot.sh"
