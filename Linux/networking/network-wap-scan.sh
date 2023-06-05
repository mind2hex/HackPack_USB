#!/usr/bin/env bash

## @author:       Johan Alexis | mind2hex
## @github:       https://github.com/mind2hex

## Project Name:  wap-scan.sh
## Description:   bash script to scan wireless access points near you area

## @style:        https://github.com/fryntiz/bash-guide-style

## @licence:      https://www.gnu.org/licences/gpl.txt
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>

#############################
##     CONSTANTS           ##
#############################  

VERSION="[v1.00]"
AUTHOR="mind2hex"

#############################
##     CONSTANTS           ##
#############################

banner(){
    echo '                                  _______  _______          '    
    echo '      O         O       |\     /|(  ___  )(  ____ )         '
    echo '       \\     //        | )   ( || (   ) || (    )|         '
    echo '        \\   //         | | _ | || (___) || (____)|         '
    echo '         \\ //          | |( )| ||  ___  ||  _____)         '
    echo '        /~~~~~\         | || || || (   ) || (               '
    echo ' ,-------------------,  | () () || )   ( || )               '
    echo ' | ,---------------, |  (_______)|/     \||/                '
    echo ' | | 01001000      | |   _______  _______  _______  _       '
    echo ' | | 01100101      | |  (  ____ \(  ____ \(  ___  )( (    /|'
    echo ' | | 01101100      | |  | (    \/| (    \/| (   ) ||  \  ( |'
    echo ' | | 01101100      | |  | (_____ | |      | (___) ||   \ | |'
    echo ' | |_______________| |  (_____  )| |      |  ___  || (\ \) |'
    echo ' |___________________|  /\____) || (____/\| )   ( || )  \  |'
    echo ' |___________________|  \_______)(_______/|/     \||/    )_)'
    echo " Version: ${VERSION} "
    echo "  Author: ${AUTHOR}  "
    echo ""
}

help(){
    echo "usage: ./wap-scan.sh [options] {-i|--interface IFACE}"
    echo "options:"
    echo "    -i,--interface <IFACE>  : Specify wireless interface       "    
    echo "    -n,--interval <n>       : Specify time interval in seconds [default:4] "	
    echo "    -v,--verbose            : Be verbose                       "
    echo "    -u,--usage              : Print usage message              "
    echo "    -h,--help               : Print this help message          "
    exit
}

usage(){
    echo "No usage message yet"
    exit 0
}

ERROR(){
    echo -e "[X] \e[0;31mError...\e[0m"
    echo "[*] Function: $1"
    echo "[*] Reason:   $2"
    echo "[X] Returning errorcode 1"
    exit 1
}

PROG_FINISH(){
    echo -e "\r========================="
    echo -e "--> Program terminated..."
    echo -e "\r========================="    
}

check_updates(){
    ## Updating remote repo
    git remote update
    if [[ $? -ne 0 ]];then
	echo "[!] Unable to update remote repo"
	return 0
    fi

    if [[ -n $(git status -uno | grep -o "Your branch is behind" ) ]];then
	echo "[#] Updates are available..."
	select var in Update Continue Exit
	do
	    if [[ $var == "Update" ]];then      # Updating program
		git pull origin master
		echo "[!] Program is updated"
		exit 0
	    elif [[ $var == "Continue" ]];then  # Continue execution Normally
		break
	    elif [[ $var == "Exit" ]];then      # Exit
		exit 0
	    fi
	done
    fi
}


argument_parser(){
    ## help if there is no arguments
    if [[ $# -eq 0  ]];then
	ERROR "argument_parser" "No arguments provided... get some help [-h]"
    fi
    
    ## parsing arguments
    while [[ $# -gt 0 ]];do
	case $1 in
	    -i|--interface) IFACE=$2 && shift && shift ;;
	    -n|--interval) INTERVAL=$2 && shift && shift ;;
	    -v|--verbose) VERBOSE="TRUE" && shift && shift ;;
	    -u|--usage) usage ;;
	    -h|--help) help ;;
	    *)help;;
	esac
    done

    ## Setting default values
    echo ${IFACE:="NONE"} &>/dev/null
    echo ${INTERVAL:="4"} &>/dev/null
    echo ${VERBOSE:="FALSE"} &>/dev/null
}

#############################
##    CHECKING AREA        ##
#############################  

argument_checker(){
    ## ROOT user check
    if [[ ${USER} != "root" ]];then
	echo -e "[!] run this program as \e[1;32mroot\e[0m to be able"
	echo -e "[!] to refresh network scanning "
	sleep 2s
    fi
    
    ## Checking wireless tools used by this program
    argument_checker_requeriments

    ## Checking interface disponibility
    argument_checker_interface "$IFACE"

    ## Checking interval  number
    argument_checker_interval "$INTERVAL"
}

argument_checker_requeriments(){
    ## iwgetid installation check
    which iwlist &>/dev/null
    if [[ $? -ne 0 ]];then # using which
        apt-cache policy iwlist &>/dev/null
        if [[ $? -ne 0 ]];then # using apt
            pacman -Q iwlist &>/dev/null
            if [[ $? -ne 0 ]];then # using pacman
                ERROR "argument_checker_requeriments" "iwlist is not installed"
            fi
        fi
    fi
}

argument_checker_interface(){
    ## iface provided check
    if [[ $1 == "NONE" ]];then
        ERROR "argument_checker_interface" "Interface not provided... Use -h for help"
    fi

    ## iface name check  [using ip command]
    ip link show $1 1>/dev/null
    if [[ $? -ne 0 ]];then # If IFACE doesn't exist.
        ERROR "argument_checker_interface" "Interface doesn't exist... Use -h for help"
    fi
}

argument_checker_interval(){
    ## Checking interval specified in seconds
    if [[ $(echo $1 | grep -o "[0-9]*" | wc -l ) -ne 1 ]];then
	ERROR "argument_checker_interval" "Invalid Interval Number $1"
    fi
}


#############################
##   PROCESSING AREA       ##
#############################

argument_processor(){

    ## if user use CTRL + C, then the program prints a finish timestamp and then exit
    trap "PROG_FINISH" EXIT

    argument_processor_print_config "$IFACE" "$INTERVAL"
    echo "Scanning..."

    
    while [[ 1 ]];do
	argument_processor_scan_info "$IFACE" #Create and fill variables used by argumentProcessorPrintInfo	
	argument_processor_print_header
	argument_processor_print_info
	sleep ${INTERVAL}s
    done
}

argument_processor_print_config(){
    printf "========== \e[0;31m Configuration \e[0m ===========\n"
    printf "[1] Wireless Interface: %-20s\n" "$1"
    printf "[2]           Interval: %-20s\n" "$2"
    printf "======================================\n"
    sleep 2s
}

argument_processor_scan_info(){
    ## Scanning for wireless AP
    info=$(iwlist $1 scan )
    if [[ $? -ne 0 ]];then
	ERROR "argument_processor_scan_info" "Error during scanning"
    fi

    ## Grepping BSSID (AP's mac)
    BSSID=($(echo "$info" | grep -o "Address.*" | cut -d " " -f 2))

    ## Grepping AP's signal power
    PWR=($(echo "$info" | grep -o -E "level=-[0-9]{1,3}" | cut -d "=" -f 2))

    ## Grepping AP's channel
    CH=($(echo "$info" | grep -E -o "Channel:[0-9]{1,3}" | cut -d ":" -f 2))

    ## Grepping ENCRYPTION
    ENC=($(echo "$info" | grep -E -o "WPA[0-9]{0,2}"))

    ## Grepping ESSID and removing spaces from it
    ESSID=($(echo "$info" | grep -o "ESSID.*" | cut -d ":" -f 2 | tr -d "\"" | tr " " "_"))
    wait
}

argument_processor_print_header(){
    clear
    printf "==========================================================\n"
    printf "\e[0;31m  N   %-18s %4s  %-2s  %-4s  %-20s  \e[0m \n" "BSSID" "PWR" "CH" "ENC" "ESSID"
    printf "==========================================================\n"
}

argument_processor_print_info(){ ## Use dialog next time
    for i in $(seq 0 $((${#ESSID[@]} - 1)));do
	printf " \e[0;32m%03d\e[0m  \e[0;36m%-18s\e[0m %4s  %2s  %-4s  \e[0;36m%-20s\e[0m \n" "$(($i + 1))" "${BSSID[$i]}" "${PWR[$i]}" "${CH[$i]}" "${ENC[$i]}" "${ESSID[$i]}"
    done
}

banner
argument_parser "$@"
argument_checker
argument_processor
exit 0


# - Log mode, like proc-mon
# - PWR signal colors indicator
