#!/bin/bash

ls initrd &>/dev/null 
if [[ $? -ne 0 ]]
then
	echo "Missing initrd folder, you have to be in the same directory"
	exit 1
else
	(cd initrd && find . | cpio -H newc -o | gzip -9 -n > ../initrd.img && echo "Image created") || ( echo "Error during creating img" && exit 1)
fi

exit 0
