#!/bin/bash
while ! dmesg | grep -q "Attached SCSI removable disk" ; do
	echo  "Waiting for the USB stick to init..."
    dmesg
    sleep 1
done  
sleep 1
dmesg | grep  "Attached SCSI removable disk"
DEV=`dmesg | grep "Attached SCSI removable disk" |head -1|sed -e 's/.*\[//' -e 's/\].*//'| tr -d "\n"`
/progs/mkblk
export BASE=/mnt/stick
echo Mount command: mount -r -t vfat "/dev/$DEV"1 $BASE
mount -r -t vfat "/dev/$DEV"1 $BASE
