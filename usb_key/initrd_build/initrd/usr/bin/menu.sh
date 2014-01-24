#! /bin/bash


## Display the menu


function display_menu 
{
    echo "" 
    echo "-- Select what you want to do:"
    echo "   1) Run a bash"
    echo "   2) Dump memory"
    echo "   3) Infect Debian"
}


function run_bash
{
    /bin/bash
    exit 0
}


function dump_memory
{
    data_name="/dev/sda2"
    data_target="/mnt/data"
    echo "Mounting $data_name to $data_target  .."
    mount $data_name $data_target
    totalMem=`cat /proc/meminfo | grep MemTotal | tr -d -c 0-9`
    totalMem=$(($totalMem/1000))
    echo -n "How MB do you want to dump ? (RAM is $totalMem MB )  "
    while read value; do
        if [ $value -lt $totalMem ] && [ $value -gt 0 ];then
            echo "Dumping memory .."
            dd if="/dev/fmem" of="$data_target/mem_dump" bs=1MB count=$value
            return 0
        else
            echo "Invalid value, try again"
        fi
    done
}

function infect_debian
{
    echo "Launching infection .."
    /usr/bin/debian_infection/infect.sh
}


display_menu

while read LINE; do
    case "$LINE" in
        "1")
            echo "You've selected to run a bash"
            run_bash
            ;;
        "2")
            dump_memory
            display_menu
            ;;
        "3")
            infect_debian
            display_menu
            ;;
        *)
            echo "Wrong option"
            display_menu
            ;;
    esac
done


exit 0



