#!/usr/bin/env bash

## @author:       mind2hex
## @github:       https://gihub.com/mind2hex
## Project Name:  network-scan.sh
## Description:   Script to discover network devices connected to the network.
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


#############################
##     BASIC FUNCTIONS     ##
#############################

help(){
    echo 'usage: ./network-monitor.sh [OPTIONS] {-i|--interface}'
    echo "Description:"
    echo "   This script scan network specified for connected hosts."
    echo 'Options: '
    echo "     -i,--interface <iface>            : Specify interface                                       "
    echo "     -r,--range <ip-addr-range/CIDR>   : Specify ip address range to scan                        "
    echo "     -o,--output <filename>            : Specify file to save output                             "
    echo "     --privscan                        : Use arp ping to scan network, requires admin privileges "
    echo "     --usage                           : Print examples of usage                                 "
    echo "     -h,--help                         : Print this help message                                 "
    echo ""
    exit 0
}

usage(){
    echo "-----------------------------------------------------"
    echo "no usage msg yet"
    echo "-----------------------------------------------------"    
    exit 0
}

ERROR(){
    echo -e "[X] \e[0;31mError...\e[0m"
    echo "[*] Function: $1"
    echo "[*] Reason:   $2"
    echo "[X] Returning errorcode 1"
    exit 1
}

argument_parser(){
    ## Arguments check
    if [[ $# -eq 0 ]];then
	    help
    fi

    while [[ $# -gt 0 ]];do
        case "$1" in
            -i|--interface) IFACE=$2                && shift && shift;;
            -r|--range) TARGET=$2                   && shift && shift;;
            -o|--output) OUTPUT=$2                  && shift && shift;;
            -p|--port-scan) PORTSCAN="TRUE"         && shift;;
            --usage) usage ;;
            -h|--help) help;;
            *) ERROR "argument_parser" "Wrong argument [$1]" ;;
        esac
    done

    ## Setting up default variables
    echo ${IFACE:="NONE"}      &>/dev/null # interface to use for network tasks
    echo ${TARGET:=""}         &>/dev/null # range specified in CIDR notation
    echo ${PORTSCAN:="FALSE"}  &>/dev/null # privscan variable
    echo ${OUTPUT:="NONE"}     &>/dev/null # output file 
}

argument_checker(){
    echo ""
    ## no checks yet
}


#############################
##     PROCESSING AREA     ##
############################# 

argument_processor(){
    local SCANTOOL=""

    # faster tools should be first
    possible_scan_tools=( 
        nmap 
        ping 
        arping
    )

    for tool in ${possible_scan_tools[@]};do
        if [[ -n $(which ${tool}) ]];then
            echo "[!] Using ${tool}"
            SCANTOOL=${tool}
            break
        fi
    done

    case $SCANTOOL in
        "nmap") nmap_scan ;;
        "ping") ping_scan ;;
        "arping") arping_scan ;;
        *) ERROR "argument_processor" "there is no tools to scan hosts in the network" ;;
    esac
}

nmap_scan(){
    nmap -sP -n -T5 $TARGET -oG -
}

ping_scan(){
    CIDR=$(echo $TARGET | cut -d "/" -f 2)
    NETWORK=$(echo $TARGET | cut -d "." -f 1-3)
    end_range=$(( (2 ** ( 32 - $CIDR )) - 2 ))
    hosts=($(eval "echo $NETWORK.{1..$end_range}"))

    for host in  ${hosts[@]};do
        echo -n -e "$host\r"
        ping -c 1 -W 0.2 -i 0.2 $host >/dev/null 2>&1
        if [[ $? -eq 0 ]];then
            echo -e "$host is alive"
        fi
    done
}

#############################
##      STARTING POINT     ##
#############################

argument_parser "$@"
argument_checker "$@"
argument_processor