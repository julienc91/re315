#/bin/bash

command=$0


usage()
{
    echo "Usage: $0 <target_device> [file.iso]"
    echo "       example: $0 /dev/sdc1"
    echo "By default the iso image is iso/infect.iso"

    exit 1
}

if [ `id -u` -ne 0 ]; then
    echo "You must run this command as root"
    exit 1
fi


if [ $# -lt 1 ]; then
    usage
fi


isoPath="iso/infect.iso"
targetPath=$1
tmpIso="/tmp/iso`date +%s`"
tmpTarget="/tmp/target`date +%s`"
sysopt="-i"

if [ $# -gt 2 ]; then
    isoPath=$2
fi

if [ ! -f $isoPath ]; then
        echo "Error! Cannot find $isoPath "
        exit 1
fi


while true; do
    read -p  "Do you want to format $targetPath ? (yes/no)" response
    case $response in
        yes )        
            echo "-- Formating $targetPath"
            mkdosfs $targetPath || exit 1
            break
            ;;
        
        no )
            break
            ;;
        * )
            echo "Wrong anwser"
            ;;
    esac
done


echo "-- Creating temp directories"
mkdir $tmpIso
mkdir $tmpTarget

echo "-- Mounting $isoPath and $targetPath"
mount $isoPath $tmpIso
mount $targetPath $tmpTarget

echo "-- Copying file"
cp "$tmpIso/"* "$tmpTarget/"

echo "-- Umounting $tmpIso and $tmpTarget"
umount $tmpIso
umount $tmpTarget



echo "-- Making device bootable"
syslinux $sysopt $targetPath



