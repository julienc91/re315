#!/bin/sh

cd initrd
find . | cpio -H newc -o | gzip > ../initrd.img
