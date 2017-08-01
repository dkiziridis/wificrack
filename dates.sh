#!/bin/bash

function dates_wl {
# Change defaults here
MIN_DATE=1
MAX_DATE=31
MIN_MONTH=1
MAX_MONTH=12
MIN_YEAR=1900
MAX_YEAR=2017

declare -a DEFAULT_DATES=("$MIN_DATE" "$MAX_DATE" "$MIN_MONTH" "$MAX_MONTH" "$MIN_YEAR" "$MAX_YEAR")
declare -a ARR_SDATES=("$MIN_DATE" "$MAX_DATE" "$MIN_MONTH" "$MAX_MONTH" "$MIN_YEAR" "$MAX_YEAR")
declare -a ARR_MESSAGE=("minimum DATE" "maximum DATE" "minimum MONTH" "maximum MONTH" "minimum YEAR" "maximum YEAR")
declare -a ARR_INPUT=("$MIN_DATE..$MAX_DATE" "$MIN_DATE..$MAX_DATE" "$MIN_MONTH..$MAX_MONTH" "$MIN_MONTH..$MAX_MONTH" "$MIN_YEAR..$MAX_YEAR" "$MIN_YEAR..$MAX_YEAR")
declare -a ARR_MIN=("$MIN_DATE" "$MIN_DATE" "$MIN_MONTH" "$MIN_MONTH" "$MIN_YEAR" "$MIN_YEAR")
declare -a ARR_MAX=("$MAX_DATE" "$MAX_DATE" "$MAX_MONTH" "$MAX_MONTH" "$MAX_YEAR" "$MAX_YEAR")

for (( i = 0; i <= 5; i++ )); do
    clear
    unset VAR
    echo -ne "--------------------- Date Generator ---------------------\n\nDate range : ${ARR_SDATES[0]}/${ARR_SDATES[2]}/${ARR_SDATES[4]} - ${ARR_SDATES[1]}/${ARR_SDATES[3]}/${ARR_SDATES[5]}\n\n"
    read -rp "Enter ${ARR_MESSAGE[$i]} (Enter to use defaults) : " VAR
    ARR_SDATES[$i]=$VAR
    while ! [[ 10#"$VAR" -ge 10#"${ARR_MIN[$i]}" && 10#"$VAR" -le 10#"${ARR_MAX[$i]}" ]]; do
        if [[ -z "$VAR" ]]; then
            ARR_SDATES[$i]=${DEFAULT_DATES[$i]}
            break
        elif [[ 10#"$VAR" -ge 10#"${ARR_MIN[$i]}" && 10#"$VAR" -le 10#"${ARR_MAX[$i]}" ]]; then
            ARR_SDATES[$i]=$VAR
            break
        else
            read -rp "$VAR is out of bounds, new input [${ARR_MIN[$i]}..${ARR_MAX[$i]}] : " VAR
            ARR_SDATES[$i]=$VAR
        fi
    done
done
DATES=$(seq -f %02g "${ARR_SDATES[0]}" "${ARR_SDATES[1]}")
if [[ -z "$DATES" ]]; then
    echo -ne "Your maximum date value is lower than your minimum.\n\n"
    read -rp "Press Enter to retry"
    dates_wl
fi
MONTHS=$(seq -f %02g "${ARR_SDATES[2]}" "${ARR_SDATES[3]}")
if [[ -z "$MONTHS" ]]; then
    echo -ne "Your maximum month value is lower than your minimum.\n\n"
    read -rp "Press Enter to retry"
    dates_wl
fi
YEARS=$(seq -w "${ARR_SDATES[4]}" "${ARR_SDATES[5]}")
if [[ -z "$YEARS" ]]; then
    echo -ne "Your maximum date value is lower than your minimum.\n\n"
    read -rp "Press Enter to retry"
    dates_wl
fi
echo "--------------------- <Date Generator> ---------------------"
echo -ne "The program will generate the following wordlist.\nDate range : ${ARR_SDATES[0]}/${ARR_SDATES[2]}/${ARR_SDATES[4]} - ${ARR_SDATES[1]}/${ARR_SDATES[3]}/${ARR_SDATES[5]}\n\nConfirm ? [yn] "
while read -rn1 KEY
do
    case "$KEY" in
        [Yy] )
            for i in ${YEARS[@]}; do
                for j in ${MONTHS[@]}; do
                    for s in ${DATES[@]}; do
                        echo "$s$j$i" >> "${ARR_SDATES[4]}-${ARR_SDATES[5]}.lst"
                        SUCCESS="$?"
                    done
                done
            done
            if [[ "$?" = 0 ]]; then
                echo -ne "\n\nWordlist generated successfully! \n${ARR_SDATES[4]}-${ARR_SDATES[5]}.lst\n"
                read -rp "Press Enter to go back." KEY
                options
            else
                read -rp "Something went wrong, check output." KEY
                options
            fi
            ;;
        [Nn] )
            options
            ;;
        * )
            echo -ne "\n[n] Cancel [y] Generate "
            ;;
    esac
done
}
dates_wl