TrueCrypt Phishing
==================

## Requirements

- gcc, libncurses
- A _silent_ USB key to boot on


## Compilation

Use the makefile to compile the program.

    make build


## Set up

Use a _silent_ USB key to boot on the targeted device and
automatically run the TrueCrypt phishing program. The passwords will
then be stored on the USB key in a file named `pkey.log`.
