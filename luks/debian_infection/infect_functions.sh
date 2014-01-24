#!/bin/sh

# $1 is the file, $2 is a space separated list of possible values
# writes the name of an existing var among the provided ones
find_var_name() { 
    file=$1
    values=$2

    for val in $values; do
        occurrences=`grep $val $file`
        if [ -n occurrences ]; then
            echo $val
            break;
        fi
    done
}

# Find one files in the candidates that is of the specified type.
# $1: filename, $2: type (shell...), $3 directory where to look recursively
find_file_by_type() {
    fname=$1
    type=$2
    location=$3

    candidates=`find $location -name $fname`
    for f in $candidates; do
        if file "$f" | grep "$type" > /dev/null 2> /dev/null; then
            echo "$f"
            return 0
        fi
    done
    return 1
}
