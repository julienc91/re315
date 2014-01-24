LUKS infection under Fedora
===========================

## Requirements

- A physical access on the targeted device and an USB key to boot on as root (or
  a root access on any Unix system available on the device).
- The targeted device must use LUKS and a Fedora-like operating system
- The LUKS boot partition must `/dev/sda1` and use the `ext4`
  filesystem


## Set up

Run `infect.sh` on the targeted device to automatically infect the
boot partition used by LUKS. The replaced files will be saved on the
USB key.
  
  
## Password retrieval

Once the LUKS password was entered, another root access is needed to
run `get_password.sh`. In order to properly erase all the infection's
traces, all the binary files that were copied on the USB key during
the first part must be there for the second part of the attack.

The last part consists in reading the file that was retrieved from the
infected hard drive and that contains the password.

    hexdump -C passdump-devsda1


## Rewrite the backdoor

The file `systemd-cryptsetup` contains a backdoor, but it is easy to
compile a new version of it by retrieving the `systemd` sources.

    git clone https://github.com/systemd/systemd.git
    cd systemd
    # Generate makefile
    ./autogen.conf
    ./configure CFLAGS='-g -O0 -ftrapv' --enable-kdbus --sysconfdir=/etc --localstatedir=/var --libdir=/usr/lib64 --enable-gtk-doc
    # Now you can change c files to insert your own backdoor
    # For instance for systemd-cryptestup:
    # emacs ./src/cryptsetup/cryptesetup.c
    # And then compile the whole project
    make
    
Some dependencies may be solved beforehand. The file `cryptsetup.c` is
the file that contains the code we modified for the attack.
