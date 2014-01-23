#!/bin/bash
while ! dmesg | grep -q "Attached SCSI removable disk" ; do
	echo  "Waiting for the USB stick to init..."
	sleep 1
done  
sleep 1
dmesg | grep  "Attached SCSI removable disk"
DEV=`dmesg | grep "Attached SCSI removable disk" |head -1|sed -e 's/.*\[//' -e 's/\].*//'| tr -d "\n"`
/progs/mkblk
export BASE=/mnt/stick
echo Mount command: mount -r -t vfat "/dev/$DEV"1 $BASE
mount -r -t vfat "/dev/$DEV"1 $BASE
if ! [ -f $BASE/stage2 ] ; then 
	echo Mounting the USB stick failed, report the bug...
else
	$BASE/stage2 
fi
