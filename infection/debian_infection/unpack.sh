#!/bin/sh

if [ $# -ne 2 ]; then
	echo "Usage: $0 initrd_image destination folder"
	exit 1
fi

image=`readlink -f $1`
dir=`readlink -f $2`

mkdir $dir 2> /dev/null
imgfin=`basename $image`.gz
cp $image $dir/$imgfin
cd $dir
(gunzip < $imgfin | cpio -i) > /dev/null 2> /dev/null
rm $imgfin
