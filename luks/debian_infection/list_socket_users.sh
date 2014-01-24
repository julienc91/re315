#!/bin/sh

stdifs=$IFS
IFS=:

for d in $PATH; do
    IFS=$stdifs
    for f in $d/*; do
        (nm -D $f 2> /dev/null | grep socket) && echo $f
    done
    IFS=:
done
