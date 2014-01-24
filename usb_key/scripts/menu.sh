#! /bin/bash


## Display the menu


function display_menu 
{
    echo "" 
    echo "-- Select what you want to do:"
    echo "   1) Run a bash"
    echo "   2) Dump memory"
    echo "   3) Infect Debian"
    echo "   4) Infect Fedora"
    echo "   5) Infect TrueCrypt (Windows/Linux)"
}


run_bash()
{
    echo "You can relaunch this menu in /usr/bin/menu.sh"
    exit 0
}


dump_memory()
{
    data_target="/dump/"
    
    totalMem=`cat /proc/meminfo | grep MemTotal | tr -d -c 0-9`
    totalMem=$(($totalMem/1000))
    echo -n "How MB do you want to dump ? (RAM is $totalMem MB )  "
    while read value; do
        if [ $value -lt $totalMem ] && [ $value -gt 0 ];then
            echo "Dumping memory .."
            dd if="/dev/fmem" of="$data_target/dump`date +%x%X`.dd" bs=1MB count=$value
            return 0
        else
            echo "Invalid value, try again"
        fi
    done

}

infect_debian()
{
    echo "Launching infection .."
    /usr/bin/debian_infection/infect.sh
}

infect_fedora()
{
    echo "Launching infection .."
    # TODO

}

infect_windows()
{
    echo "Launching infection .."
    # TODO

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
        "4")
            infect_fedora
            display_menu
            ;;
        "5")
            infect_windows
            display_menu
            ;;
        *)
            echo "Wrong option"
            display_menu
            ;;
    esac
done


exit 0



