#!/bin/bash

ls initrd.img &>/dev/null
if [[ $? -ne 0 ]]
then
	echo "Missing initrd.img, you have to be in the same directory"
	exit 1
else
	(mkdir initrd && cd initrd && gunzip < ../initrd.img | cpio -i && echo "Image uncompressed") || (echo "Error during uncompressing image" && exit 1)
fi

exit 0
