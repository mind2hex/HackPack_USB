#!/usr/bin/env bash

## @author:       Johan Alexis
## @github:       https://gihub.com/mind2hex
## Project Name:  network-monitor.sh
## Description:   script to monitor hosts connected to the network.
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

regEx="(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-b9]|[01]?[0-9][0-9]?)"
macRegEx="[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}"

#############################
##     BASIC FUNCTIONS     ##
#############################

help(){
    echo 'usage: ./network-monitor.sh [OPTIONS] {-i|--interface}'
    echo "Description:"
    echo "   Files generated and used by this program:            "
    echo "     -->  $HOME/.config/lan_DB/<SSID>                   "
    echo "     -->  $HOME/.config/lan_DB/<SSID>/authorized        "
    echo "     -->  $HOME/.config/lan_DB/<SSID>/unauthorized      "
    echo "     -->  $HOME/.config/lan_DB/<SSID>/.checksum.txt     "
    echo 'Options: '
    echo "     -i,--interface <iface>            : Specify interface                                       "
    echo "     -r,--range <ip-addr-range/CIDR>   : Specify ip address range to scan                        "
    echo "     --privscan                        : Use arp ping to scan network, requires admin privileges "
    echo "     -P,--print-mode                   : Just print known and unknown group                      "
    echo "     -f,--flush-arp                    : flush arp cache. Recomended when scanning network first time"
    echo "     --add <mac>                       : add mac address to known group                          "
    echo "     --remove <mac>                    : remove mac address from known group                     "
    echo "     --restart                         : delete and generate configuration files and the DB      "
    echo "     --usage                           : Print examples of usage                                 "
    echo "     -h,--help                         : Print this help message                                 "
    echo ""
    exit 0
}

usage(){
    echo "-----------------------------------------------------"
    echo "# To scan a network"
    echo "# This is the first thing you need to do"
    echo "# Simply use the flag -i <interface> -r <ip/range>"
    echo "  $ ./network-monitor.sh -i eth0 -r 192.168.0.1/24 "
    echo "-----------------------------------------------------"
    echo "# To add an address to Authorized group and to remove"
    echo "# the same address"
    echo "  $ ./network-monitor.sh --add ff:ff:ff:ff:ff:ff "
    echo "  $ ./network-monitor.sh --remove ff:ff:ff:ff:ff:ff "
    echo "-----------------------------------------------------"
    echo "# To name a host in Authorized group"
    echo "  $ ./network-monitor.sh --name-host home ff:ff:ff:ff:ff:ff "
    echo "-----------------------------------------------------"    
    echo "# Printing Mode, just run the program without args"
    echo "  $ ./network-monitor.sh "
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
	    -P|--print-mode) PRINTMODE="TRUE"       && shift;;
	    -f|--flush-arp) FLUSH="TRUE"            && shift;;
	    --privscan) PRIVSCAN="TRUE"             && shift;;
	    --add) AUTHADDR=(${AUTHADDR[@]} $2 )    && shift && shift;;
	    --remove) UNAUADDR=(${UNAUADDR[@]} $2 ) && shift && shift;;
	    --restart) RESTART="TRUE"               && shift ;;
	    --usage) usage ;;
	    -h|--help) help;;
	    *) ERROR "argument_parser" "Wrong argument [$1]" ;;
	esac
    done

    ## Setting up default variables
    echo ${IFACE:="NONE"}      &>/dev/null # interface to use for network tasks
    echo ${TARGET:=""}         &>/dev/null # range specified in CIDR notation
    echo ${PRINTMODE:="FALSE"} &>/dev/null # if True, just print the DB and exit
    echo ${FLUSH:="FALSE"}     &>/dev/null # if True, flush arp cache
    echo ${PRIVSCAN:="FALSE"}  &>/dev/null # privscan variable
    echo ${AUTHADDR:="NONE"}   &>/dev/null # 
    echo ${UNAUADDR:="NONE"}   &>/dev/null #
    echo ${RESTART:="FALSE"}   &>/dev/null # if True, clean the DB
}

argument_checker(){
    ## Checking external programs used by this program
    argument_checker_requeriments
    
    ## configuration files check
    argument_checker_files
    
    ## Print mode only print the DB so there is no need to do more checks
    if [[ $PRINTMODE == "TRUE" ]];then
        return 0
    fi

    ## Checking Mac address syntax
    argument_checker_mac  ## Uses global var $AUTHADDR $UNAUADDR $NAMEHOST $UNAMEHOST        
    
    ## Checking interface
    if [[ "${IFACE}" != "NONE" ]];then
	argument_checker_interface $IFACE
    fi

    ## ip scanning range
    if [[ -n "${TARGET}" ]];then
	argument_checker_range $TARGET
    fi

    if [[ "${IFACE}" != "NONE" && -z "${TARGET}" ]];then
	ERROR "argument_checker" "Interface specified but not range"
    elif [[ "${IFACE}" == "NONE" && -n "${TARGET}" ]];then
	ERROR "argument_checker" "Range specified but not interface"
    fi

    ## Checking address existence inside auth group of the DB
    if [[ "${AUTHADDR}" != "NONE" ]];then
	## Only executing this check if AUTHADDR is specified
	argument_checker_auth_addr # "${AUTHADDR}" "${UNAUADDR}" --> arrays
    fi

    

    
    return 0
}

argument_checker_requeriments(){
    ## revisando que las herramientas necesarias esten instaladas
    for i in $(echo "fping nmap iwgetid iw arping");do
	which $i &>/dev/null
	if [[ $? -ne 0 ]];then 
	    apt-cache policy $i  &>/dev/null
	    if [[ $? -ne 0 ]];then # using apt
		pacman -Q $i &>/dev/null
		if [[ $? -ne 0 ]];then # using pacman
		    ERROR "argument_checker_requeriments" "$i is not installed"
		fi
	    fi
	fi
    done
}

argument_checker_files(){
    ## revisando que los archivos de configuracion esten instalados
    DIRDB="$HOME/.config/lan_DB"
    SSID=$(iwgetid | grep -o '".*"' | tr -d '\"')
    AUTHFILE="${DIRDB}/${SSID}/authorized"
    UNAUFILE="${DIRDB}/${SSID}/unauthorized"
    CHECKSUM="${DIRDB}/${SSID}/.checksum.txt" 
    
    ## /home/$USER/.config file check
    if [[ ! -e /home/$USER/.config ]];then
	mkdir /home/$USER/.config # Creating .config file if it not exist
    fi
    
    ## Checking for program files existence
    for i in "$DIRDB" "$AUTHFILE" "$UNAUFILE" "$CHECKSUM";do
	if [[ -e $i ]];then
	    continue
	else
	    generate_files
	    DB_checkSum
	    break
	fi
    done
}

argument_checker_mac(){
    ## This function checks if mac address are valid

    ## Checking Mac address from AUTHADDR
    if [[ ${AUTHADDR} != "NONE" ]];then
	local aux=$(expr ${#AUTHADDR[@]} - 1)
	for i in $(seq 0 ${aux});do
	    if [[ -z $(echo ${AUTHADDR[$i]} | grep -o -E "${macRegEx}" | head -n 1) ]];then
		ERROR "argument_checker_mac" "Invalid Mac address ${AUTHADDR[$i]}"
	    fi
	done
    fi

    if [[ ${UNAUADDR} != "NONE" ]];then
	local aux=$(expr ${#UNAUADDR[@]} - 1)
	for i in $(seq 0 ${aux});do
	    if [[ -z $(echo ${UNAUADDR[$i]} | grep -o -E "${macRegEx}" | head -n 1) ]];then
		ERROR "argument_checker_mac" "Invalid Mac address ${AUTHADDR[$i]}"
	    fi
	done
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

    ## iface connection check
    if [[ $(cat /sys/class/net/$1/carrier) -ne 1 ]];then 
        ERROR "argument_checker_interface" "Interface is not connected to a network"
    fi
}

argument_checker_range(){
    ## ip check
    if [[ -z $(echo $1 | grep -E -o "${regEx}") ]];then
	ERROR "argument_checker_range" "Invalid ip address specification"
    fi
        
    ## CIDR check
    if [[ -z $(echo $1 | grep -E -o "\/[0-9]{1,2}") ]];then
       ERROR "argument_checker_range" "Invalid CIDR specification"
    fi

    ## Do more CIDR and IP checks here
}

argument_checker_auth_addr(){
    ## Checking AUTHADDR array
    if [[ ${AUTHADDR} != "NONE" ]];then
        aux=$(expr ${#AUTHADDR[@]} - 1)

	## Iterating AUTHADDR array
        for i in $(seq 0 $aux);do
	    ## Check if address is already in authorized file
            if [[ -n $(cat $AUTHFILE | grep "${AUTHADDR[$i]}")  ]];then
                ERROR "argument_checker_auth_addr" "MAC: ${AUTHADDR[$i]} is already in $AUTHFILE"
	    fi

	    ## Check if address is in unauthorized file
            if [[ -z $(cat $UNAUFILE | grep "${AUTHADDR[$i]}") ]];then
                ERROR "argument_checker_auth_addr" "MAC: ${AUTHADDR[$i]} is not in $UNAUFILE"
            fi
        done
    fi
    
    ## Checking UNAUADDR array
    if [[ ${UNAUADDR} != "NONE" ]];then
        aux=$(expr ${#UNAUADDR[@]} - 1)

	## Iterating UNAUADDR array
        for i in $(seq 0 $aux);do
	    ## Check if address is already in unauthorized file
            if [[ -n $(cat $UNAUFILE | grep "${UNAUADDR[$i]}" ) ]];then
                ERROR "argument_checker_auth_addr" "MAC: ${UNAUADDR[$i]} is already in $UNAUFILE"
	    fi

	    ## Check if address is in authorized file
            if [[ -z $(cat $AUTHFILE | grep "${UNAUADDR[$i]}") ]];then
                ERROR "argument_checker_auth_addr" "MAC: ${UNAUADDR[$i]} is not in $AUTHFILE "
            fi
        done
    fi    
}

generate_files(){
    ## Generate files necesary for this program
    ## This function usually is called from argument_checker function
    
    trap 'ERROR "generate_files" "Impossible "' 8
    echo "[@] files_generator  may  run  automatically  in  case the "
    echo "[@] configuration files or the database  does not exist or "
    echo "[@] if it is called by arguments"
    echo -e "========================================================="
    echo "[*] Creating DataBase..."
    echo -ne "[1] " && mkdir -v "$DIRDB"
    echo -ne "[2] " && mkdir -v "$DIRDB/$SSID"
    echo "[3] Generating $AUTHFILE" && touch $AUTHFILE
    echo "[4] Generating $UNAUFILE" && touch $UNAUFILE
    echo "[5] Generating $CHECKSUM" && md5sum $AUTHFILE $UNAUFILE > $CHECKSUM
    echo "[*] Done..."
    echo -e "=========================================================\n"
}

#############################
##     PROCESSING AREA     ##
############################# 

argument_processor(){
    
    ## if TRUE delete DB and create it again
    if [[ $RESTART == "TRUE" ]];then 
	rm -rf $DIRDB
	generate_files
    fi

    ## Just printmode 
    if [[ $PRINTMODE == "TRUE" ]];then
	printDB
	exit 0
    fi

    ## Flush DNS
    if [[ $FLUSH == "TRUE" ]]; then
	echo -e "\e[33m[!] Warning, flushing arp cache \e[0m"
	sleep 3s
	sudo ip -s -s neigh flush all
    fi    

    ## Scan mode, only if IFACE and TARGET is provided.
    if [[ "$IFACE"  != "NONE" && -n $TARGET ]];then
	##  ARP CACHE UPDATING
	echo -e "[*] Scanning network \e[32m$TARGET\e[0m"
	echo "[*] Updating arp cache tables"
	echo "[*] This can take a while "
	argument_processor_scan "$IFACE" "$TARGET"
	argument_processor_ARP_table_handler "$IFACE"
	echo "[*] Finished..."
    fi

    ## Adding a host to authorization file
    if [[ ${AUTHADDR} !=  "NONE" ]];then
	num=$(expr ${#AUTHADDR[@]} - 1)
	for i in $(seq 0 $num);do
	    movAddr "${AUTHADDR[$i]}" "$UNAUFILE" "$AUTHFILE"
	done
    fi
    
    ## Removing a host from authorization file
    if [[ ${UNAUADDR} != "NONE" ]];then
	num=$(expr ${#UNAUADDR[@]} - 1)
	for i in $(seq 0 $num);do
	    movAddr "${UNAUADDR[$i]}" "$AUTHFILE" "$UNAUFILE"
	done
    fi

    ## Final step
    printDB
}

argument_processor_scan(){
    ## This function updates the arp table using a nmap ping scan
    ## $1 = $IFACE
    ## $2 = $TARGET = <ip>/CIDR

    ## 2 scans to ensure all hosts are pinged
    
    ## Scan 1
    if [[ ${PRIVSCAN} == "TRUE" ]];then
	sudo nmap -e $1 -sn -T5 $2 &>/dev/null          # PRIVILEGED SCAN: ARP SCAN
    else
	nmap -e $1 --send-ip -sP -n -T5 $2 &>/dev/null  # UNPRIVILEGED SCAN: PING SCAN
    fi
    
    if [[ $? -ne 0 ]];then
	ERROR "argument_processor_scan" "Error during the ping scan: $1 $2"
    fi

    ## Scan 2
    if [[ ${PRIVSCAN} == "TRUE" ]];then
	sudo nmap -e $1 -sn -T5 $2 &>/dev/null          # PRIVILEGED SCAN: ARP SCAN
    else
	nmap -e $1 --send-ip -sP -n -T5 $2 &>/dev/null  # UNPRIVILEGED SCAN: PING SCAN
    fi
    
    if [[ $? -ne 0 ]];then
	ERROR "argument_processor_scan" "Error during the ping scan: $1 $2"
    fi
    
    return 0
}

argument_processor_ARP_table_handler(){
    ## This function extract a list of mac address and a list of ip address
    ## from the arp cache table
    ## After that, it search in the config files for matches, if there is no
    ## matches that means that the host is new, so it goes inside unauthorized file

    ## Getting arp info
    arpInfo=$(/usr/sbin/arp --device $1 -n | grep --invert-match "incomplete")
    wait

    ## Grep macs from arpInfo... Maybe i can improve this regular expression
    arpMacs=($(echo $arpInfo | grep -o -E "[0-9a-f]{2}\:[0-9a-f\:]*" | tr "\n" " "))

    ## Grep ip address
    arpAddr=($(echo $arpInfo | grep -o -E "$regEx" | tr "\n" " "))

    ## Actual BSSID from the interface
    BSSID=$(/sbin/iwgetid -r)
    
    num=$(expr ${#arpMacs[@]} - 1)
    for i in $(seq 0 $num);do
	## Ensuring to not repeat hosts in the AUTH and UNAU files
	if [[ -z $(cat $AUTHFILE | grep ${arpMacs[$i]}) && -z $(cat $UNAUFILE | grep ${arpMacs[$i]}) ]];then
	    printf "%-13s %17s  %-8s %-8s \n" ${arpAddr[$i]} ${arpMacs[$i]} ${IFACE:0:7} ${BSSID:0:7} >> $UNAUFILE
	else
	    continue
	fi
    done
}

printDB(){
    ## Esta funcion solo muestra los
    ## archivos de configuracion sin modificarlos
    
    ## Printing authorized file
    header=`printf "  %-13s %-17s  %-8s %-8s %-8s\n" "IP-ADDRESS" "MAC-ADDRESS" "IFACE" "SSID" "NAME"`
    echo -e "\e[32m" # Green
    echo "======== AUTHORIZED GROUP ========================================"
    echo "$header"
    echo "=================================================================="
    ## Sorting output
    cat "$AUTHFILE" |  grep --invert-match "^\#" | sort --version-sort | nl -w 1 | tr "\t" " " 

    ## Printing unauthorized file
    echo -e "\e[31m" # RED
    echo "======== UNAUTHORIZED GROUP ======================================"
    echo "$header"
    echo "=================================================================="
    ## Sorting output
    cat "$UNAUFILE" | grep --invert-match "^\#" | sort --version-sort | nl -w 1 | tr "\t" " "
    echo -e "\e[0m"
}

movAddr(){
    ## This function move address $1 from $src to $dst
    # $1 MAC
    # $2 src_file
    # $3 dst_file
    local aux
    
    ## Checking if MAC is not in dst
    if [[ -n $(cat $3 | grep "$1") ]];then
	ERROR "movAddr" "MAC: $1 is already in $3"
    fi

    ## Checking if MAC is in src
    if [[ -z $(cat $2 | grep "$1") ]];then
	ERROR "movAddr" "MAC: $1 is not in $2"
    fi

    ## Checking if MAC is in both [src,dst]
    if [[ -n $(cat $2 | grep "$1") && -n $(cat $3 | grep "$1") ]];then
	echo "[X] MAC: $1 is in both files. "
	echo "[!] Deleting $1 from $AUTHFILE"
	aux=$(cat $AUTHFILE | grep -n "$1" | grep -E -o "^[0-9]{1,3}")
	echo "$(sed ${aux}d $AUTHFILE)" > $AUTHFILE
    fi

    data=$(cat $2 | grep "$1")
    aux=$(cat $2 | grep -n "$1" | grep -E -o "^[0-9]{1,3}")
    echo "$(sed ${aux}d $2)" > $2
    echo "$data" >> $3

    ## Removing empty lines from files
    AUTHRESULT=$(cat $AUTHFILE | grep "\S" --color=never)
    echo "$AUTHRESULT" > $AUTHFILE
    
    UNAURESULT=$(cat $UNAUFILE | grep "\S" --color=never)
    echo "$UNAURESULT" > $UNAUFILE
}

DB_checkSum(){
    ## Checking if the DB has been changed using md5 verification sum
    md5sum --check $CHECKSUM &>/dev/null
    local aux=$?
    if [[ $RESTART != "TRUE" ]];then
	if [[ $aux -ne 0 ]];then
	    ERROR "DB_checkSum" "DB has been corrupted. Use --restart"
	fi
    fi
}

DB_checkSum_update(){
    md5sum $AUTHFILE $UNAUFILE > $CHECKSUM
}

#############################
##      STARTING POINT     ##
#############################
argument_parser "$@"
argument_checker "$@"

# Checksum of the database to see if it has been modified 
DB_checkSum

argument_processor
DB_checkSum_update
exit 0

# - Add name host utility
# Now the script identifies SSID, but it's better
# idea to use BSSID of the AP and give it router name automatically

# netmask
