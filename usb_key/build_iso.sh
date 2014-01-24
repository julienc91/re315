#!/bin/bash



outputName="iso/infect.iso"
initrdPath="initrd_build/initrd.img"
syslinuxPath="conf/syslinux.cfg"
kernelPath="kernel_image/vmlinuz.img"

echo -n "Building initrd ..."
cd initrd_build/
./compressImg.sh
echo "Done"
cd ..

echo "Generating $outputName"
genisoimage -o $outputName $initrdPath $syslinuxPath $kernelPath
echo "Done"





