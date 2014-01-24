#!/bin/bash

usage()
{
    echo "Usage: $0 <usb_mount_folder> <saving_folder>"
    echo "       example: $0 /mnt/usb_key ~/bitlocker_keys"

    exit 1
}

if [ $# -lt 2 ]; then
    usage
fi

if [ -d $2 ]; then
    if [ -d $1 ]; then
	if [[ -n $(ls -A $1/*.BEK 2> /dev/null) ]]; then
	    cp $1/*.BEK $2
	    echo "BitLocker keys were successfully copied in $2"
	else
	    echo "There is no BEK file in $1"
	fi
    else
	echo "$1 is not a correct folder"
    fi
else
    echo "$2 is not a correct folder"
fi
