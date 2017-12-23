#!/bin/bash
set -e
IMAGE_URL="https://downloads.raspberrypi.org/raspbian_lite_latest"

if [ "$(id -u)" != "0" ]
then
   echo "This script must be run as root" 1>&2
   exit 1
fi

apt-get -y install unzip wget

if [ -z "$IMAGE_FILE" ]
then
  echo "no image file path provided! downloading the image!"
  wget -O raspbian_lite_latest.zip $IMAGE_URL
  IMAGE_FILE=`zipinfo -1 raspbian_lite_latest.zip`
  unzip raspbian_lite_latest.zip
fi

if [ -z "$IMAGE_SIZE" ]
then
  echo "no numeric value provided! Defaulting to zero!"
  SIZE=0
else
  case $IMAGE_SIZE in
     (*[!0-9]*|'')
        echo "no numeric value provided! Defaulting to zero!"
        SIZE=0
        ;;
     (*)
        SIZE=$IMAGE_SIZE
        ;;
  esac
fi

if [ -f ${IMAGE_FILE} ]
then
  if [ $SIZE -gt 0 ]
  then
    NEW_SIZE=$(($SIZE * 1024))
    OFFSET_BOOT_SIZE=`/sbin/fdisk -lu ${IMAGE_FILE}  | tail -n 2 | head -n 1 | awk '{ print $2 }'`
    OFFSET_ROOTFS_SIZE=`/sbin/fdisk -lu ${IMAGE_FILE} | tail -n 1 | head -n 1 | awk '{ print $2 }'`
    OFFSET_BOOT=$(($OFFSET_BOOT_SIZE * 512))
    OFFSET_ROOTFS=$(($OFFSET_ROOTFS_SIZE * 512))


    echo "Resizing the image"
    dd if=/dev/zero bs=1024k count=$NEW_SIZE >> $IMAGE_FILE
    dev_loop_0=`/sbin/losetup -f --show ${IMAGE_FILE}`
    dev_loop_1=`/sbin/losetup -f --show -o ${OFFSET_ROOTFS} ${IMAGE_FILE}`
    echo "Use the following commands inside the fdisk prompt: "
    echo "1: p to list the partions"
    echo "2: d to delete a partion"
    echo "3: 2 to select the partition to delete"
    echo "4: n to create a new partion"
    echo "5: p to create a new primary partion"
    echo "6: 2 to select the new partion number"
    echo "7: Start sector of the new partion => $OFFSET_ROOTFS_SIZE"
    echo "8: Last sector keep the default value!"
    echo "9: w to write the changes"
    fdisk $IMAGE_FILE
    e2fsck -f $dev_loop_1
    resize2fs $dev_loop_1
    losetup -d $dev_loop_0 $dev_loop_1
  fi
else
  print 'Error: provided image file does not exist'
  exit
fi
