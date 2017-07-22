#!/bin/bash

function crack {
clear
read -p "Try cracking $ESSID now ? [yn] : " ANSWER
if [[ "$ANSWER" = [Yy] ]]; then
	readarray -t FILES < <(find `pwd` -name "*.cap")
    if [[ -z "$FILES" ]]; then
    	echo "No .cap files found."
    	read -p "Enter full path to .cap file : " CAP
    else
    	echo "Select a .cap file to crack"
        select CHOICE in "${FILES[@]}"; do
        	[[ -n "$CHOICE" ]] || { echo "Invalid choice. Try again." >&2; continue; }
            break
        done
        read -r CAP <<< "$CHOICE"
	fi
	read -p "Enter full path to wordlist : " WORDLIST
    aircrack-ng -w "$WORDLIST" "$CAP"
fi
}
crack