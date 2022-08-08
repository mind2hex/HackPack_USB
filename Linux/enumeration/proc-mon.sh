#!/usr/bin/env bash

## @author:       Johan Alexis | mind2hex
## @github:       https://github.com/mind2hex

## Project Name:  proc-mon.sh
## Description:   bash script to monitor the processes that are activated in a certain period of time

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

#############################
##   BASIC FUNCTIONS       ##
#############################    

banner(){
    echo 
    echo -e "\e[32m" '     dMMMMb  dMMMMb  .aMMMb  .aMMMb  dMMMMMP .dMMMb  .dMMMb '
    echo             '   dMP.dMP dMP.dMP dMP"dMP dMP"VMP dMP     dMP" VP dMP" VP  '
    echo             '  dMMMMP" dMMMMK" dMP dMP dMP     dMMMP    VMMMb   VMMMb    '
    echo             ' dMP     dMP"AMF dMP.aMP dMP.aMP dMP     dP .dMP dP .dMP    '
    echo             'dMP     dMP dMP  VMMMP"  VMMMP" dMMMMMP  VMMMP"  VMMMP"     '
    echo -e "\e[31m" '                                                            '
    echo             '    dMMMMMMMMb .aMMMb  dMMMMb  dMP dMMMMMMP .aMMMb  dMMMMb  '
    echo             '   dMP"dMP"dMPdMP"dMP dMP dMP amr    dMP   dMP"dMP dMP.dMP  '
    echo             '  dMP dMP dMPdMP dMP dMP dMP dMP    dMP   dMP dMP dMMMMK"   '
    echo             ' dMP dMP dMPdMP.aMP dMP dMP dMP    dMP   dMP.aMP dMP"AMF    '
    echo             'dMP dMP dMP VMMMP" dMP dMP dMP    dMP    VMMMP" dMP dMP     '
    echo -e "\e[0m"
    echo "Version: $VERSION"
    echo "Author:  mind2hex"
}

help(){
    echo "usage: process-monitor.sh [options] "
    echo "Options:                            "
    echo "     -i,--interval <n>       : Specify refresh interval. [WARNING]    "
    echo "                               Low interval values may use a lot of resources"
    echo "     -u,--user <user>        : Specify filter: user                   "
    echo "     -p,--pid <pid>          : Specify filter: process id             "
    echo "     -l,--log <file>         : Save log of processes to a file        "
    echo "     --exclude-sys           : Exclude main system process            "
    echo "     --exclude-proc <name>   : Exclude process that match with <name> "
    echo "     --match <keyword>       : Highlight keyword if found in output   "
    echo "     -u,--usage              : See usage message                      "
    echo "     -h,--help               : See this help message                  "
    exit 0
}

usage(){
    echo  -e "================================================================"
    echo " INFORMATION:                                                       "
    echo "[!] When the program is executing, a temporal file is generated     "
    echo "    using the format file.XXX                                       "
    echo "[!] Using low interval values may use a lot of cpu                  "
    echo  -e "================================================================"
    echo "[!] Usage Examples:                                                 "
    echo "[1] Show only specified user                                        "
    echo "        $ ./proc-mon.sh -u root                                     "
    echo "[2] Specify logfile                                                 "
    echo "        $ ./proc-mon.sh -l mylogfile                                "
    echo "[3] Specify refresh interval                                        "
    echo "        $ ./proc-mon.sh -i 0.1                                      "
    echo  -e "================================================================"    
    exit 0
}

ERROR(){
    echo -e "[X] \e[0;31mError...\e[0m"
    echo "[*] Function: $1 "
    echo "[*] Reason:   $2 "
    echo "[X] returning errorcode 1"
    exit 1    
}

argument_parser(){
    ## This loop handle CLI arguments
    while [[ $# -gt 0 ]];do
	case "$1" in
	    -i|--interval) INTERVAL=$2 && shift && shift ;;
	    -u|--user) USERSPEC=$2 && shift && shift ;;
	    -p|--pid)  PID=$2 && shift && shift ;;
	    -l|--log)  LOGFILE=$2 && shift && shift;;
	    --exclude-sys) ExcludeSys="TRUE" && shift;;
	    --exclude-proc) ExcludeProcess="$2" && shift && shift;;
	    --match) Match="$2" && shift && shift;;
	    --usage) usage ;;
	    -h|--help) help ;;
	    *) ERROR "argument_parser" "Wrong argument [$key]" ;;
        esac 
    done


    
    ## Setting up default variables
    echo ${INTERVAL:="1"} &>/dev/null
    INTERVAL=`echo $INTERVAL | grep -o -E "[0-9\.]{1,}" | tr -d "\n"`
    
    ${USERSPEC:="ALL"} &>/dev/null

    if [[ -z $PID ]];then
	PID="ALL"
    else
	PID=`echo $PID | grep -o -E "[0-9]{1,}" | tr -d "\n"`
    fi
    
    echo ${LOGFILE:="FALSE"} &>/dev/null
    
    echo ${ExcludeSys:="FALSE"} &>/dev/null

    echo ${ExcludeProcess:="FALSE"} &>/dev/null
    
    echo ${Match:="FALSE"} &>/dev/null
}

#############################
##     CHECKING AREA       ##
#############################    

argument_checker(){
    ## $1 = INTERVAL
    ## $2 = USERSPEC
    ## $3 = PID
    ## $4 = LOGFILE
    
    ## interval number check
    argument_checker_interval "$1"
    
    ## USERSPEC check
    argument_checker_user_check "$2"

    ## PID check
    argument_checker_PID_check "$3"

    ## logfile check
    argument_checker_file_check "$4"
}

argument_checker_interval(){
    ## Checking decimal points
    if [[ $( echo "$1" | grep -c "\." ) -gt 1 ]];then
	ERROR "argument_checker_interval" "Interval number has more than one decimal point"
    fi

    ## Code goes here if there is more checks
}

argument_checker_user_check(){
    ## if no user specified return 0
    $(test "$1" == "ALL")&& return 0

    ## checking user existence in /etc/passwd file
    $(test -z `cat /etc/passwd | cut -d ":" -f 1 | grep -w -o "$1"`)&& ERROR "argument_checker_user_check" "User $1 doesn't exist"
}

argument_checker_PID_check(){
    ## if no PID specified return 0
    $(test "$1" == "ALL")&& return 0
    
    ## ERROR if user don't specify a valid number cause of autoasign conditional in function argument_parser
    $(test -z $PID) && ERROR "argument_checker_PID_check" "Invalid PID: $PID"

    ## PID can't be zero or less than zero
    $(test "$1" -le 0) && ERROR "argument_checker_PID_check" "PID can't be zero or lesser than zero"    
}

argument_checker_file_check(){
    ## if FILE == FALSE means log file not specificated
    $(test "$1" == "FALSE")&& return 0

    ## error if logfile exist
    $(test -e "$1")&& ERROR "argument_checker_file_check" "LogFile $1 already exist"
}    

#############################
##     PROCESSING AREA     ##
#############################    

argument_processor(){
    ## $1 = INTERVAL
    ## $2 = USERSPEC
    ## $3 = PID
    ## $4 = LOGFILE
    ## $5 = ExcludeSys
    ## $6 = ExcludeProcess
    
    argument_processor_print_configuration "$1" "$2" "$3" "$4" "$5" "$6"

    ## Creating Temporal File and linking if LOGFILE specified
    argument_processor_file_generator "$4"

    ## Trap for CTRL + C
    trap 'rm $TempFile;exit ' EXIT
    
    argument_processor_print_header
    
    while true;do
	argument_processor_update_info 
	argument_processor_update_arrays   # $userArr $pidArr $cmdArr
	argument_processor_update_temporal_file
	sleep ${INTERVAL}
    done
}

argument_processor_print_configuration(){
    #### FILTERS ######## CONFIGURATIONS #####
    # $2 = $USERSPEC   | $1 = $INTERVAL
    # $3 = $PID        | $4 = $LOGFILE
    # $5 = $ExcludeSys |
    # $6 = $ExcludePr..|
    
    echo -e "==== \e[0;31mFilters\e[0m ============ # === \e[0;31mConfigurations\e[0m ======"
    printf "[1]        user: %-8s # [1] interval: %-8s\n" "${2:0:8}" "$1"
    printf "[2]         PID: %-8s # [2]      log: %-8s\n" "$3" "$4"
    printf "[3] exclude-sys: %-8s # %-8s\n"               "$5" ""
    printf "[4] exclude-pro: %-8s # %-8s\n"               "${6:0:8}"
    printf "%-25s # %-25s\n" "=========================" "========================="
    echo "[!] Press CTRL-C to stop the program "
    sleep 4s
}

argument_processor_print_header(){
    clear
    printf "==========================================================\n"
    printf "%-8s   %-8s   %-50s\n" "USERSPEC" "PID" "CMD"
    printf "==========================================================\n"
    sleep 1s
    
}    

argument_processor_file_generator(){
    ## Generating random temporary file
    TempFile=$(mktemp file.XXXX)
    #TempFile=$(echo $RANDOM | base64 | tr -d "=") # TempFile is used in other functions
    touch $TempFile

    if [[ "$1" != "FALSE" ]];then
	## linking tempfile to logfile
	ln -f $TempFile $1 2>/dev/null

	## checking if logfile and temp file are in the same partition.
	if [[ $? -ne 0 ]];then
	    rm $TempFile
	    ERROR "argument_processor_file_generator" "Impossible to create hard links between differents partitions"
	fi
    fi
}

argument_processor_update_info(){
    ## info gathering
    info=$(ps -ef h)  # variable used in other functions
    
    ## USERSPEC FILTER
    if [[ $USERSPEC != "ALL" ]];then
	info=$(echo "$info" | grep -w "${USERSPEC:0:7}")
    fi

    ## PID FILTER
    if [[ $PID != "ALL" ]];then
	info=$(echo "$info" | grep -w "$PID")
    fi

    ## Excluding last command 'info=$(ps)... PID'
    info=`echo "$info" | grep --invert-match "ps -ef h"`

    ## Excluding shell ID
    info=$(echo "$info" | grep --invert-match "$$")
}

argument_processor_update_arrays(){
    ## Separating data into arrays
    userArr=($(echo "$info" | grep -o -E "^.{1,8}"))
    pidArr=($(echo "$info"  | grep -o -E "^.{1,8}[\ ]*[0-9]{1,7}" | grep -o -E " [0-9]{1,7}" | grep -o "[0-9]*"))
    cmdArr=($(echo "$info" | grep -o -E " [0-9]\:[0-9]{2}.*" | tr " " "."))

    ## if i find a better way to separate by arrays then code goes here
}

argument_processor_update_temporal_file(){
    for i in $(seq 0 $((${#userArr[@]} - 1)));do
	line=$(printf "\e[1m%-8s  \e[1;31m %-8s   \e[0m%-50s" "${userArr[$i]}" "${pidArr[$i]}" "${cmdArr[$i]:0:50}")
	if [[ -z $(cat "$TempFile" | grep -w "${pidArr[$i]}") ]];then

	    ## Checking for Match var
	    if [[ $(echo "$line" | grep --ignore-case -o "${Match}" | head -n 1) ]];then
		## High light matches using grep... Pretty cool right?
		echo "${line}" | grep --color "${Match}" >> $TempFile
		echo "${line}" | grep --color "${Match}"
	    else
		echo "$line" >> $TempFile
		echo "$line"
	    fi
	fi
    done
}


#############################
##      STARTING POINT     ##
#############################    

banner
argument_parser "$@"
argument_checker "$INTERVAL" "$USERSPEC" "$PID" "$LOGFILE"
argument_processor "$INTERVAL" "$USERSPEC" "$PID" "$LOGFILE" "$ExcludeSys" "$ExcludeProcess"
exit 0

# fix ${string:="test"} execution problem
# develop Match utility to allow more than one matching keyword
# delete points that are replacing spaces in the output lines
# Sometimes a bug doesn't let the program show the cmd of some processes i don't know why
