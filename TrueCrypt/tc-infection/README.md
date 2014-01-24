TrueCrypt Bootloader Infection
==============================

## Requirements

* A physical access on the targeted device and an USB key to boot on as root (or
  a root access on any Unix system available on the device).
* The targeted device must use TrueCrypt full disk encryption. It has only been
  tested with an encrypted Windows, but the boot should be independant from the
  OS, and the attack is expected to work on Linux systems as well.
* The LUKS boot partition must `/dev/sda1` and use the `ext4`
  filesystem

## Content of this directory

* *evilgroom*: this directory contains the sources of the attack against
  TrueCrypt.
* *TrueCrypt-src*: contains the sources of the Boot part of TrueCrypt (from the 
  windows sources
* *infect-tc.sh*: interactive usage of the evilgroom infection.

## Evilgroom directory

Everything mentionned here happens in the *evilgroom* directory.

### Quick Start

If you are in a hurry and want to try it right now:

* Build the project with:

    make

* To run evilgroom (device_to_infect might be a block device or a file
  containing the dd of a hard drive):
    
    ./evilgroom <device_to_infect>

* To demonstrate the infection, run: 
    
    make emul

This command compiles the program if it has not been already, and runs it on
a sample hard drive that contained an uninfected TrueCrypt. The hardrive is
infected by evilgroom, them booted with qemu-system-i686 (you might want to
replace this command with something that is present on your computer).

Enter the password (the correct one is "secret"). If it is ok, you will see a
series of "Read Error" because this is not a full hard drive image.

Exit the VM, evilgroom is launched again on the infected hard drive, and you
will see the password that you entered appear ("secret"). If you entered a 
wrong password and shut down the VM, the last wrong password will be seen by
evilgroom.

### Content

This directory contains the sources of the attack against TrueCrypt.

* *bak.devsda*: this is a sample for the project demonstration. It is the
beginning of a TrueCrypt encrypted hard drive (enough to illustrate the boot
infection).
* *evilgroom.c*: Main source code of the infection. More documentation inside.
* *logger.asm*: Contains the 16 bits intel asm code for the password
interception. This code is injected into the targetted binary. It defines some
globals used by evilgroom.c during the infection process.
* *Makefile*: Allows the compilation and the demonstration of the project (make, make emul, make clean, make mrproper).

## TrueCrypt-src directory

This directory contains a part of the TrueCrypt sources for windows. This part
is only the sources necessary for the boot (it might even not be makeable).
It is just there as a support if the reader wants a better understanding of the
attack.

Interesting files:

* Boot/Windows/BootSector.asm: Code that is placed in the executable section of
  the MBR.
* Boot/Windows/BootDefs.h: Included in BootSector.asm, mainly contains
  very interesting constants.
* Boot/Windows/BootMain.cpp: Contains the main of the TrueCrypt bootloader as
  well as the AskPassword function.
* Boot/Windows/BootMain.h: Header of BootMain.cpp, contains the password
  structure, some prototypes and constants.

