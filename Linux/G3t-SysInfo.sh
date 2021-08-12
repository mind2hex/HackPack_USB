#!/usr/bin/bash

SystemInfo(){
    clear
    Output_File=${Loot_Dir}/SystemInfo.txt
    echo "" > ${Output_File}

    # OS INFO SECTION
    echo "[!] OS Info:"        | tee ${Output_File} -a
    echo "        $(uname -a)" | tee ${Output_File} -a
    echo ""                    | tee ${Output_File} -a

    # CPU INFO SECTION
    echo "[!] CPU Info:"       | tee ${Output_File} -a
    for i in $(lscpu -e | replace " " "_");do
	echo "        $i" | replace "_" " "  | tee ${Output_File} -a
    done
    
}

Warning(){
    echo -e "\e[0;33m $1 \e[0m"
}

## MAIN
clear

# Checking main Loot Directory
Loot_Dir=${PWD}/LOOT
if [[ !( -e $Loot_Dir )]];then  
    mkdir $Loot_Dir
fi

# Checking loot file
Loot_Dir=${Loot_Dir}/$(hostname)
if [[ !(-e $Loot_Dir) ]];then
    mkdir $Loot_Dir
else
    Warning "Loot directory with a similar hostname it's already created. "
    PS3="Do you want to continue?: "
    select opt in "Yes" "No"
    do
	case $opt in
	    "Yes") break;;
	    "No") exit;;
	    *) echo " Wrong Option " ;;
	esac
    done
fi

SystemInfo $Loot_Dir
