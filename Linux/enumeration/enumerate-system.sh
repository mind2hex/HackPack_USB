#!/usr/bin/bash

# this program recolects computer info like
#        - users personal folder info
#        - hardware info
#        - software info


LOOT_DIR=${PWD}/LOOT
LOOT_HOSTNAME_DIR=${LOOT_DIR}/$(hostname)

get_computer_info(){

    # get operative system info
    get_OS

    # inspect env variables
    get_env

    # inspect applications and services
    get_appNservices

    # inspect installed aplications
    get_installed_applications

    # schedule jobs
    get_cronjobs

    # inspect network info
    get_network

    # inspect mounted file systems
    get_mounted_fs

    # root directory extraction
    get_root_directory
    
    # home info extraction
    #get_home_directories
}

get_OS(){
    # operative system information
    local LOOT_HOSTNAME_OS_FILE=${LOOT_HOSTNAME_DIR}/01.operative_system_info.txt
    echo "" > ${LOOT_HOSTNAME_OS_FILE}

    # distribution and version
    echo "[!] Distribution: $(cat /etc/issue) " | tee -a ${LOOT_HOSTNAME_OS_FILE}
    echo "[!] Kernel Version: $(uname -a) "     | tee -a ${LOOT_HOSTNAME_OS_FILE}
}

get_env(){
    local LOOT_HOSTNAME_ENV_FILE=${LOOT_HOSTNAME_DIR}/02.environment_variables.txt
    echo "" > ${LOOT_HOSTNAME_ENV_FILE}

    
    echo "[!] Env variables: "  | tee -a ${LOOT_HOSTNAME_ENV_FILE}
    env | sed 's/^/\t/'         | tee -a ${LOOT_HOSTNAME_ENV_FILE}
}

get_appNservices(){
    local LOOT_HOSTNAME_APP_SERV_FILE=${LOOT_HOSTNAME_DIR}/03.applicationNservices.txt
    
    echo "" > ${LOOT_HOSTNAME_APP_SERV_FILE}
    echo "============== CURRENT PROCESSES ====================" | tee -a ${LOOT_HOSTNAME_APP_SERV_FILE}
    ps -elf                                     | tee -a ${LOOT_HOSTNAME_APP_SERV_FILE}
    
    echo -e "\n\n============== CURRENT SERVICES  ====================" | tee -a ${LOOT_HOSTNAME_APP_SERV_FILE}
    cat /etc/service                            | tee -a ${LOOT_HOSTNAME_APP_SER_FILE}
}

get_installed_applications(){
    local LOOT_HOSTNAME_INSTALLED_APPS_FILE=${LOOT_HOSTNAME_DIR}/04.installed_applications.txt
    echo "" > ${LOOT_HOSTNAME_INSTALLED_APPS_FILE}
    echo "============== INSTALLED APPLICATIONS/PROGRAMS ========================" | tee -a ${LOOT_HOSTNAME_INSTALLED_APPS_FILE}
    apt list --installed | sed 's/^/\t/' > ${LOOT_HOSTNAME_INSTALLED_APPS_FILE}
}

get_cronjobs(){
    local LOOT_HOSTNAME_CRONTAB_FILE=${LOOT_HOSTNAME_DIR}/05.cronjobs.txt
    echo "" > ${LOOT_HOSTNAME_CRONTAB_FILE}
    echo "[!] crontab -l: "                      | tee -a ${LOOT_HOSTNAME_CRONTAB_FILE}
    crontab -l | sed -e 's/^/\t/'                | tee -a ${LOOT_HOSTNAME_CRONTAB_FILE}
    echo -e "\n\n[!] /etc/cron* : "              | tee -a ${LOOT_HOSTNAME_CRONTAB_FILE}
    cat /etc/cron* | sed -e 's/^/\t/'            | tee -a ${LOOT_HOSTNAME_CRONTAB_FILE}
    echo -e "\n\n[!] /etc/cron.d/* : "           | tee -a ${LOOT_HOSTNAME_CRONTAB_FILE}
    cat /etc/cron.d/* | sed -e 's/^/\t/'         | tee -a ${LOOT_HOSTNAME_CRONTAB_FILE}
    echo -e "\n\n[!] /etc/cron.daily/* : "       | tee -a ${LOOT_HOSTNAME_CRONTAB_FILE}
    cat /etc/cron.daily/* | sed -e 's/^/\t/'     | tee -a ${LOOT_HOSTNAME_CRONTAB_FILE}
    echo -e "\n\n[!] /etc/cron.hourly/* : "      | tee -a ${LOOT_HOSTNAME_CRONTAB_FILE}
    cat /etc/cron.hourly/* | sed -e 's/^/\t/'    | tee -a ${LOOT_HOSTNAME_CRONTAB_FILE}
    echo -e "\n\n[!] /etc/cron.monthly/* : "     | tee -a ${LOOT_HOSTNAME_CRONTAB_FILE}
    cat /etc/cron.monthly/* | sed -e 's/^/\t/'   | tee -a ${LOOT_HOSTNAME_CRONTAB_FILE}
    echo -e "\n\n[!] /etc/at.allow : "           | tee -a ${LOOT_HOSTNAME_CRONTAB_FILE}
    cat /etc/at.allow | sed -e 's/^/\t/'         | tee -a ${LOOT_HOSTNAME_CRONTAB_FILE}
    echo -e "\n\n[!] /etc/at.deny : "            | tee -a ${LOOT_HOSTNAME_CRONTAB_FILE}
    cat /etc/at.deny | sed -e 's/^/\t/'          | tee -a ${LOOT_HOSTNAME_CRONTAB_FILE}
    echo -e "\n\n[!] /etc/anacrontab : "         | tee -a ${LOOT_HOSTNAME_CRONTAB_FILE}
    cat /etc/anacrontab | sed -e 's/^/\t/'       | tee -a ${LOOT_HOSTNAME_CRONTAB_FILE}


}

get_network(){
    local LOOT_HOSTNAME_NETWORK_FILE=${LOOT_HOSTNAME_DIR}/06.network.txt
    echo "" > ${LOOT_HOSTNAME_NETWORK_FILE}
    echo "[!] ifconfig -a: "     | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}
    ifconfig | sed -e 's/^/\t/'  | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}
    echo -e "\n\n[!] ip link: "  | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}
    ip link  | sed -e 's/^/\t/'  | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}
    echo -e "\n\n[!] ip addr: "  | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}
    ip addr  | sed -e 's/^/\t/'  | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}
    echo -e "\n\n[!] /etc/resolve.conf: "  | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}
    cat /etc/resolv.conf | grep --invert-match -E "^\#" | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}
    echo -e "\n\n[!] /etc/networks : "     | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}
    cat /etc/networks  | sed -e 's/^/\t/'  | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}
    echo -e "\n\n[!] lsof -i : "     | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}
    lsof -i  | sed -e 's/^/\t/'      | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}
    echo -e "\n\n[!] lsof -i :80,443 (http,https): "     | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}
    lsof -i :80,443  | sed -e 's/^/\t/'      | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}
    echo -e "\n\n[!] netstat -antup: "       | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}
    netstat -antup  | sed -e 's/^/\t/'       | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}
    echo -e "\n\n[!] last : "       | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}
    last  | sed -e 's/^/\t/'        | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}    

    if [[ ${PRIVILEGED} -eq 1 ]];then
	echo -e "\n\n[!] iptables -L: "      | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}
	sudo iptables -L | sed -e 's/^/\t/'  | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}
    fi

    echo -e "\n\n[!] dnsdomainname: "  | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}
    dnsdomainname  | sed -e 's/^/\t/'  | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}    

    local target_dir="/etc/NetworkManager/system-connections"
    echo -e "\n\n[!] ${target_dir}/* : "  | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}
    if [[ -d ${target_dir} ]];then
	if [[ ${PRIVILEGED} -eq 1 ]];then
	    for i in ${target_dir}/*;do
		echo "---> ${target_dir}/${i}"   | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}
		cat ${i} | sed -e 's/^/\t/'      | tee -a ${LOOT_HOSTNAME_NETWORK_FILE}
	    done
	fi
    fi
}

get_mounted_fs(){
    local LOOT_HOSTNAME_MOUNTED_FS_FILE=${LOOT_HOSTNAME_DIR}/07.mounted_fs.txt
    echo "" > ${LOOT_HOSTNAME_MOUNTED_FS_FILE}
    echo -e "\n\n[!] mount : "                      | tee -a ${LOOT_HOSTNAME_MOUNTED_FS_FILE}
    mount  | sed -e 's/^/\t/'                | tee -a ${LOOT_HOSTNAME_MOUNTED_FS_FILE}
    echo -e "\n\n[!] df : "                         | tee -a ${LOOT_HOSTNAME_MOUNTED_FS_FILE}
    df  | sed -e 's/^/\t/'                   | tee -a ${LOOT_HOSTNAME_MOUNTED_FS_FILE}
    echo -e "\n\n[!] /etc/fstab : "                 | tee -a ${LOOT_HOSTNAME_MOUNTED_FS_FILE}
    cat /etc/fstab  | sed -e 's/^/\t/'       | tee -a ${LOOT_HOSTNAME_MOUNTED_FS_FILE}    

}


get_usersNgroups(){
    local LOOT_HOSTNAME_USERSNGROUPS_FILE=${LOOT_HOSTNAME_DIR}/08.users_groups.txt
    echo "" > ${LOOT_HOSTNAME_USERSNGROUPS_FILE}
    echo -e "\n\n[!] /etc/passwd : "         | tee -a ${LOOT_HOSTNAME_USERSNGROUPS_FILE}
    cat /etc/passwd  | sed -e 's/^/\t/'      | tee -a ${LOOT_HOSTNAME_USERSNGROUPS_FILE}
    echo -e "\n\n[!] /etc/group : "         | tee -a ${LOOT_HOSTNAME_USERSNGROUPS_FILE}
    cat /etc/group  | sed -e 's/^/\t/'      | tee -a ${LOOT_HOSTNAME_USERSNGROUPS_FILE}

    if [[ ${PRIVILEGED} -eq 1 ]];then
	echo -e "\n\n[!] /etc/shadow :"               | tee -a ${LOOT_HOSTNAME_USERSNGROUPS_FILE}
	sudo cat /etc/shadow  | sed -e 's/^/\t/'      | tee -a ${LOOT_HOSTNAME_USERSNGROUPS_FILE}
	echo -e "\n\n[!] /etc/sudoers :"              | tee -a ${LOOT_HOSTNAME_USERSNGROUPS_FILE}
	sudo cat /etc/shadow  | sed -e 's/^/\t/'      | tee -a ${LOOT_HOSTNAME_USERSNGROUPS_FILE}	
    fi
}

get_root_directory(){
    if [[ ${PRIVILEGED} -eq 1 ]];then
	sudo rsync -a --info=progress2 --exclude="lost+found" --exclude=".cache" /root/ ${LOOT_HOSTNAME_DIR}/root
    else
	# trying to read root directory without root privileges
	ls /root 2>/dev/null
	if [[ $? -eq 0 ]];then
	    rsync -a --ignore-errors --info=progress2 --exlude="lost+found" --exlude=".cache" /root/ ${LOOT_HOSTNAME_DIR}/root
	fi
    fi


}


get_home_directories(){
    if [[ ${PRIVILEGED} -eq 1 ]]; then
	sudo rsync -z -a --info=progress2 --exclude="lost+found" --exclude=".cache" /home/ $LOOT_HOSTNAME_DIR
    else
	rsync -z -a --ignore-errors --info=progress2 --exclude="lost+found" --exclude=".cache" /home/ $LOOT_HOSTNAME_DIR
    fi


}


warning(){
    echo -e "\e[0;33m $1 \e[0m"
}

error(){
    local RED="\e[1;31m"
    local NNN="\e[0m"
    echo -e "========= ${RED} ERROR  ${NNN} =========="
    echo -e "--> $1"
    echo -e "--> $2"
    echo -e "Leaving the program... "
    
    exit
}

main() {
    clear

    PRIVILEGED=1

    # check if program is executed with root privileges

    if [[ $(id -u ) -ne 0 ]]; then
	PRIVILEGED=0
	warning "This program is not being execute with privilege rights"
	warning "You'll not be able to get all files from home directory"
	warning "You'll not be able to get some hardware and software info"
	warning "Do you want to continue?"
	PS3="--> "
	select opt in "Yes" "No"
	do
	    case $opt in
		"Yes") clear && break;;
		"No") exit;;
		*) echo " Wrong Option " ;;
	    esac
	done	
    fi

    # check if $LOOT_DIR is already created
    if [[ !( -d $LOOT_DIR ) ]];then  
	mkdir $LOOT_DIR
	if [[ $? -ne 0 ]];then
	    error "Error when creating ${LOOT_DIR}" "main::mkdir $LOOT_DIR"
	fi
    fi

    # check if $LOOT_FILE is already created
    if [[ !( -d $LOOT_HOSTNAME_DIR) ]];then
	mkdir $LOOT_HOSTNAME_DIR
	if [[ $? -ne 0 ]];then
	    error "Error when creating ${LOOT_HOSTNAME_DIR}" "main::mkdir $LOOT_HOSTNAME_DIR"
	fi	
    else
	warning "Loot directory with a similar hostname it's already created."
	warning "Do you cant to continue?"
	PS3="--> "
	select opt in "Yes" "No"
	do
	    case $opt in
		"Yes") break;;
		"No") exit;;
		*) echo " Wrong Option " ;;
	    esac
	done
    fi

    clear
    get_computer_info 
}

main $@

# to-do
# --> get_cronjobs:  Clasificar a que archivo adentro del directorio pertenece cada output
# --> get_home_directories: Copiar y comprimir automaticamente el directorio objetivo
# --> get_root_directory:   Copiar y comprimir automaticamente el directorio objetivo
