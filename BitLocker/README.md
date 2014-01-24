BitLocker without TPM
=====================


## Requirements

It is sufficient to have access to the usb media which is used to boot
the system in order to have a full access to the targeted system
later on.


The script `bypass_bitlocker.sh` simply copies BEK files in the given
folder. It is then possible to bypass the BitLocker boot system by
copying the saved BEK files onto a new usb key and inserting it while
booting the targeted system.
