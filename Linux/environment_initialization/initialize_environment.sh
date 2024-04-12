#!/bin/bash

# Show messages to the terminal
log_msg(){
    # $1 = msg
    # $2 = type (ERROR, WARNING, DEBUG)
    RED="\e[31m"
    YELLOW="\e[33m"
    BLUE="\e[34m"

    if [[ $2 == "ERROR" ]];then
        COLOR="${RED}"
    elif [[ $2 == "WARNING" ]];then
        COLOR="${YELLOW}"
    else
        COLOR="${BLUE}"
    fi

    END_COLOR="\e[0m"

    echo -n "---------------------------------------------------"
    echo -e "\n[!] ${COLOR} $1 ${END_COLOR}"
}

# Function to detect distribution and package manager
detect_package_manager(){
    if [[ -f /etc/debian_version ]];then
        PACKAGE_MANAGER="apt"
        PACKAGE_MANAGER_UPDATE="apt update"
        PACKAGE_MANAGER_UPGRADE="apt upgrade -y"
        PACKAGE_MANAGER_INSTALL="apt install -y"
        PACKAGE_MANAGER_UNINSTALL="apt remove"
    elif [[ -f /etc/redhat-release  ]];then
        PACKAGE_MANAGER="yum"
        PACKAGE_MANAGER_UPDATE="yum update"
        PACKAGE_MANAGER_UPGRADE="yum upgrade"
        PACKAGE_MANAGER_INSTALL="yum install"
        PACKAGE_MANAGER_UNINSTALL="yum remove"
    elif [[ -f /etc/arch-release ]];then
        PACKAGE_MANAGER="pacman"
        PACKAGE_MANAGER_UPDATE="pacman -Syu"
        PACKAGE_MANAGER_UPGRADE=${PACKAGE_MANAGER_UPDATE}
        PACKAGE_MANAGER_INSTALL="pacman -S --noconfirm"
        PACKAGE_MANAGER_UNINSTALL="pacman -R"
    else
        log_msg "Distribution not supported." "ERROR"
        exit 1
    fi

    log_msg "Packet manager detected: ${PACKAGE_MANAGER}"
}

# Function to update and upgrade before installing other tools
update_upgrade(){
    log_msg "Updating system: ${YELLOW}${PACKAGE_MANAGER_UPDATE}${END_COLOR}"
    sleep 2
    sudo ${PACKAGE_MANAGER_UPDATE}
    if [[ $? -ne 0 ]];then
        log_msg "Unable to update using ${PACKAGE_MANAGER_UPDATE}" "ERROR"
        exit 1
    fi

    log_msg "Upgrading system: ${YELLOW}${PACKAGE_MANAGER_UPGRADE}${END_COLOR}"
    sleep 2
    sudo ${PACKAGE_MANAGER_UPGRADE}
    if [[ $? -ne 0 ]];then
        log_msg "Unable to upgrade using ${PACKAGE_MANAGER_UPGRADE}" "ERROR"
        exit 1
    fi
}

# Setup directories for tools and proyects
setup_directories(){
    pentest_dir="${HOME}/PENTEST"
    dev_dir="${pentest_dir}/dev/"
    github_dir="${pentest_dir}/github/"

    conky_dir="${HOME}/.config/conky/"
    wordlist_dir="/usr/share/wordlists/"

    special_directories=(
        ${conky_dir}
        ${dev_dir}
        ${github_dir}/{my_tools,cloned_tools}
        ${dev_dir}/{python,cc++,bash,web}
    )

    privileged_special_directories=(
        ${wordlist_dir}
    )
    
    log_msg "Creating special directories"
    for directory in ${special_directories[@]};do
        echo -e "\t- ${directory}"
        mkdir -p ${directory}
    done

    log_msg "Creating privileged special directories"
    for directory in ${privileged_special_directories[@]};do
        echo -e "\t- ${directory}"
        sudo mkdir -p ${directory}
    done
}

# preconfiguration of some tools
tools_preconfiguration(){
    log_msg "Tools preconfiguration"

    ## Kismet configuration
    echo -e "\t== Kismet configuration =="
    read -p "Do you want to remove all kismet previous installation (if exists) [Y/N]?" choice
    if [[ "${choice}" = "Y" ]];then
        for directories in "/usr/local/bin/kismet" "/usr/local/share/kismet" "/usr/local/etc/kismet";do
            echo -e "\t- deleting ${directories}*"
            sudo rm -rfv ${directories}*
        done
    fi
    echo -e "\t- Adding kismet.list to /etc/apt/sources.list.d/kismet.list"
    if ! [[ -f /etc/apt/sources.list.d/kismet.list ]];then
        wget -O - https://www.kismetwireless.net/repos/kismet-release.gpg.key --quiet | gpg --dearmor | sudo tee /usr/share/keyrings/kismet-archive-keyring.gpg >/dev/null
        echo 'deb [signed-by=/usr/share/keyrings/kismet-archive-keyring.gpg] https://www.kismetwireless.net/repos/apt/release/jammy jammy main' | sudo tee /etc/apt/sources.list.d/kismet.list >/dev/null
    fi

}

# Install tools using package manager
install_tools_via_pkg_manager(){
    general_use_tools=(
	    docker.io docker-compose terminator conky-all neofetch
    )
    programming_tools=(
	    python3 python3-venv python3-pip emacs gdb git code build-essential
    )
    network_hacking_tools=(
	    nmap reaver wifite aircrack-ng  gnuradio wireshark gqrx-sdr netdiscover kismet bettercap
    )
    anonymizing_tools=(
	    tor torbrowser-launcher proxychains4 macchanger
    )
    web_hacking_tools=(
	    gobuster wfuzz sqlmap
    )
    security_tools=(
	    rkhunter chkrootkit clamav hydra john hashcat
    )

    log_msg "Installing general use tools"
    for tool in ${general_use_tools[@]};do
        echo -e -n "\t - Installing ${tool}..."
        sudo ${PACKAGE_MANAGER_INSTALL} ${tool}  >/dev/null 2>&1
        if [[ $? -ne 0 ]];then
            echo -e -n "${RED} Error, unable to install.${END_COLOR}\n"
        else
            echo ""
        fi
    done

    log_msg "Installing programming tools"
    for tool in ${programming_tools[@]};do
        echo -e -n "\t - Installing ${tool}..."
        sudo ${PACKAGE_MANAGER_INSTALL} ${tool} >/dev/null 2>&1
        if [[ $? -ne 0 ]];then
            echo -e -n "${RED} Error, unable to install.${END_COLOR}\n"
        else
            echo ""
        fi
    done

    log_msg "Installing network hacking tools"
    for tool in ${network_hacking_tools[@]};do
        echo -e -n "\t - Installing ${tool}..."
        sudo ${PACKAGE_MANAGER_INSTALL} ${tool} >/dev/null 2>&1
        if [[ $? -ne 0 ]];then
            echo -e -n "${RED} Error, unable to install.${END_COLOR}\n"
        else
            echo ""
        fi
    done

    log_msg "Installing anonymizing tools"
    for tool in ${anonymizing_tools[@]};do
        echo -e -n "\t - Installing ${tool}..."
        sudo ${PACKAGE_MANAGER_INSTALL} ${tool} >/dev/null 2>&1
        if [[ $? -ne 0 ]];then
            echo -e -n "${RED} Error, unable to install.${END_COLOR}\n"
        else
            echo ""
        fi
    done

    log_msg "Installing web hacking tools"
    for tool in ${web_hacking_tools[@]};do
        echo -e -n "\t - Installing ${tool}..."
        sudo ${PACKAGE_MANAGER_INSTALL} ${tool} >/dev/null 2>&1
        if [[ $? -ne 0 ]];then
            echo -e -n "${RED} Error, unable to install.${END_COLOR}\n"
        else
            echo ""
        fi
    done

    log_msg "Installing security tools"
    for tool in ${security_tools[@]};do
        echo -e -n "\t - Installing ${tool}..."
        sudo ${PACKAGE_MANAGER_INSTALL} ${tool} >/dev/null 2>&1
        if [[ $? -ne 0 ]];then
            echo -e -n "${RED} Error, unable to install.${END_COLOR}\n"
        else
            echo ""
        fi
    done

}

# install tools cloning git repositories
install_tools_via_git(){

    # installing exploitdb and searchsploit
    log_msg "Installing exploitdb from github"
    if ! [[ -d /opt/exploit-database ]];then
        sudo git clone https://gitlab.com/exploit-database/exploitdb.git /opt/exploit-database
        sudo ln -sf /opt/exploit-database/searchsploit /usr/local/bin/searchsploit
        cp -n /opt/exploit-database/.searchsploit_rc ~/
    fi

    # SecLists
    log_msg "Installing SecLists wordlists to ${wordlist_dir}/SecLists"
    if ! [[ -d ${wordlist_dir}/SecLists ]];then
        sudo git clone https://github.com/danielmiessler/SecLists ${wordlist_dir}/SecLists
    fi
    
    # Rockyou.txt
    log_msg "Install rockyou.txt wordlist to ${wordlist_dir}/rockyou.txt"
    if ! [[ -f ${wordlist_dir}/rockyou.txt ]];then
        sudo wget 'https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt' -O ${wordlist_dir}/rockyou.txt
    fi

    # CLONNING MY TOOLS
    my_tools=(
        webToolkit
        NetRunner
        TCPCobra
        Hackpack_usb
    )
    for tool in ${my_tools[@]};do
        log_msg "Installing ${tool} to ${github_dir}/my_tools/${tool}"
        if ! [[ -d ${github_dir}/my_tools/${tool} ]];then
            git clone https://github.com/mind2hex/${tool} ${github_dir}/my_tools/${tool}
        fi
    done

    #  ALFA Network AWUS036AC Driver installation for ubuntu
    log_msg "Installing ALFA Network drivers"
    read -p "Do you want to install ALFA Network AWUS036AC drivers? (Y/N) : " choice
    if [[ "${choice}" = "Y" ]];then
        system=$(uname -v | grep --ignore-case -E -o "(ubuntu|kali)" | cut -d " " -f 1)
        if [[ $system = "Ubuntu" ]];then
            if ! [[ -d ${github_dir}/cloned_tools/rtl8812au ]];then
                git clone https://github.com/aircrack-ng/rtl8812au.git ${github_dir}/cloned_tools/rtl8812au
            fi
        fi
    fi	

    # LinPeas
    log_msg "Installing LinPease"
    mkdir -p ${github_dir}/cloned_tools/LinPeas/
    curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh > ${github_dir}/cloned_tools/LinPeas/linpeas.sh
}

configure_tools(){
    # CONFIGURING CONKY
    cp ./conky.conf ${conky_dir}
}


additional_configurations(){
    ## CONFIGURING SHELL PROFILE
    foo=$(cat ~/.bashrc | grep)
    cp ./profile ~/.profile
    echo -e "\nsource ~/.profile" >> ~/.bashrc

    ## CONFIGURING /etc/hosts
    wifi_pineapple_addr="172.16.42.1"
    hosts=$(cat /etc/hosts | grep -o "${wifi_pineapple_addr}")
    if [[ -z "${hosts}" ]];then
	    echo -e "172.16.42.1\twifi-pineapple.net\t# port 1471" | sudo tee -a /etc/hosts > /dev/null
    fi
}



detect_package_manager
#tools_preconfiguration  # before update_upgrade to reflect changes in sources
#update_upgrade    
#setup_directories
#install_tools_via_pkg_manager
#install_tools_via_git
exit 0