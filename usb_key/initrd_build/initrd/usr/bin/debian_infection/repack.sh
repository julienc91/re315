#!/bin/sh

if [ $# -ne 2 ]; then
	echo "Usage: $0 source_folder destination_image"
	exit 1
fi

image=`readlink -f $2`
dir=`readlink -f $1`
cpioimg=/tmp/initrd.cpio
tgzimg=${cpioimg}.gz

rm $cpioimg 2> /dev/null
rm $tgzimg 2> /dev/null

cd $dir

(find ./ | cpio -H newc -o > $cpioimg) > /dev/null 2> /dev/null
gzip $cpioimg > /dev/null 2> /dev/null
mv $tgzimg $image

rm $cpioimg 2> /dev/null
