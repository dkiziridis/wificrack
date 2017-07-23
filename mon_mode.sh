#!/bin/bash

function unset_mon {
if [[ -z "$STATE" ]]; then
    echo
    echo "Monitor mode was not set on $IFACE."
    sleep 2
else
    echo
    echo "Disabling Monitor Mode for $IFACE..."
    echo
    echo "Bringing $IFACE down..."
    IFACE=$(ls /sys/class/net | grep $IFACE)
    ifconfig $IFACE down >> /dev/null
    echo "Reverting MAC address to factory default..."
    macchanger -p $IFACE  >> /dev/null
    echo "Bringing $IFACE up..."
    ifconfig $IFACE up >> /dev/null
    echo "Disabling monitor mode for $IFACE..."
    airmon-ng stop $IFACE >> /dev/null
    echo "$IFACE is no longer in monitor mode."
    unset STATE
    sleep 2
    IFACE=$(sed 's/mon//g' <<< $IFACE)
fi
}
function set_mon {
if [[ -z "$STATE" ]]; then
    LIST="1 2 3 4 5 6 7 8 9 10 11 12 13 14 131 132 132 133 133 134 134 135 136 136 137 137 138 138 36 40 44 48 52 56 60 64 100 104 108 112 116 120 124 128 132 136 140 149 153 157 161 165"
    echo
    echo "Setting $IFACE in Monitor Mode..."
    echo
    echo "Creating new interface..."
    read -p "Set Channel or (Press Enter to skip) : " REPLY
    if [[ $LIST =~ (^|[[:space:]])"$REPLY"($|[[:space:]]) ]]; then 
        airmon-ng start $IFACE $REPLY >> /dev/null
    elif [[ ! $LIST =~ (^|[[:space:]])"$REPLY"($|[[:space:]]) && "$REPLY" = "" ]]; then 
        airmon-ng start $IFACE >> /dev/null
    else
        echo "Invalid Channel \"$REPLY\" entered. "
        read -p "Retry ? [yn] " ASK
        if [[ "$ASK" = [Yy] && "$REPLY" != "" ]]; then
            set_mon
            unset REPLY
            unset ASK
        fi
    fi
    airmon-ng start $IFACE >> /dev/null
    IFACE=$(ls /sys/class/net | grep $IFACE)
    echo "Bringing $IFACE down..."
    ifconfig $IFACE down >> /dev/null
    echo "Changing MAC address for $IFACE"
    macchanger -m 00:11:22:33:44:55 $IFACE >> /dev/null
    echo "Bringing $IFACE up..."
    ifconfig $IFACE up >> /dev/null
    NEWMAC=$(iw $IFACE info | grep addr | awk '{print $2}')
    STATE=$(echo $IFACE | grep mon)
    echo "$IFACE is in monitor mode and it's MAC address is: $NEWMAC"
else
    echo
    echo "$IFACE already in monitor mode."
    NEWMAC=$(iw $IFACE info | grep addr | awk '{print $2}')
    sleep 2
fi
}
function multiple_interfaces {
STATE=$(echo $IFACE | grep mon)
menu
while read -n1 CHAR
do
    case $CHAR in
        e )
            set_mon
            echo
            clear
            multiple_interfaces
            break
            ;;
        d )
            unset_mon
            clear
            multiple_interfaces
            break
            ;;
        q )
            clear
            exit 0
            ;;
        * )
            echo -ne "\nInvalid character '$CHAR' entered. $PROMPT"
    esac
done
}

function menu {
clear
if [[ "$IFACENUM" -gt 1 ]]; then
    SWITCH="c) Change Interface"
fi
if [[ -n $STATE ]]; then
    MM=ON
else
    MM=OFF
fi
echo "----------------------- WiFiCrack v0.5_beta -----------------------"
echo "WLAN Interface : $IFACE"
if [[ "$MM" = "ON" ]]; then
    echo "Monitor Mode   : >> $MM <<"
else
    echo "Monitor Mode   : $MM"  
fi
echo
echo "e) Enable <M/M>"
echo "d) Disable <M/M>"
echo "q) Abort!"
echo
PROMPT="Choose : "
echo -n "$PROMPT"
}
function list_ifaces {
clear
readarray -t IFACES < <(ls /sys/class/net | grep wl)
echo "Select an interface (WLAN Card) and press Enter"
select CHOICE in "${IFACES[@]}"; do
    [[ -n "$CHOICE" ]] || { echo "Invalid choice. Try again." >&2; continue; }
    break
done
read -r IFACE <<< "$CHOICE"
}
function check_wlan {
IFACENUM=$(ls /sys/class/net/ | grep wl |  wc -l)
if [[ "$IFACENUM" -gt 1 ]]; then
    echo "You have multiple wlan interfaces."
    list_ifaces
    multiple_interfaces
elif [[ "$IFACENUM" -eq 1 ]]; then
    single_interface
elif [[ "$IFACENUM" -eq 0 ]]; then
    echo "No WLAN interfaces found."
fi
}
check_wlan