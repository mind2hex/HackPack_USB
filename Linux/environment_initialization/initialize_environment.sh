#!/bin/bash

# Show messages to the terminal
log_msg(){
    # $1 = msg
    # $2 = type (ERROR, WARNING, DEBUG)
    RED="\e[31m"
    YELLOW="\e[33m"
    BLUE="\e[34m"
    END_COLOR="\e[0m"

    if [[ $2 == "ERROR" ]];then
        COLOR="${RED}"
    elif [[ $2 == "WARNING" ]];then
        COLOR="${YELLOW}"
    else
        COLOR="${END_COLOR}"
    fi

    echo -n "---------------------------------------------------"
    echo -e "\n[!] ${COLOR} $@ ${END_COLOR}"
}

# Function to detect distribution and package manager
detect_package_manager(){
    if [[ -f /etc/debian_version ]];then
        PACKAGE_MANAGER="apt-get"
        PACKAGE_MANAGER_UPDATE="apt-get update"
        PACKAGE_MANAGER_UPGRADE="apt-get upgrade -y"
        PACKAGE_MANAGER_INSTALL="apt-get install -y"
        PACKAGE_MANAGER_UNINSTALL="apt-get remove"
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
    wordlist_dir="/usr/share/wordlists/"

    special_directories=(
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

# install tools using different resources (github, extern pages, package repositories, etc)
install_tools(){
    install_tools_with_pkg_manager(){
        # $1 tools category
        log_msg "Do you want to install ${YELLOW}$1${END_COLOR}?\n${tools[@]}"
        read -p "[y/n]: " choice
        if [[ "${choice}" = "y" ]];then
            for tool in ${tools[@]}; do
                echo -e -n "\t -> Installing $tool..."
                sudo $PACKAGE_MANAGER_INSTALL $tool >/dev/null 2>&1
                if [[ $? -eq 0 ]];then
                    echo "Done"
                else
                    echo "Failed"
                fi
            done
        fi
    }

    install_tools_from_github(){
        for tool_url_path in ${github_tools[@]};do
            
            # tool name
            tool=$( echo "$tool_url_path" | cut -d "@" -f 1 )

            # tool url (github, gitlab, etc) should be a git reopsitory
            url=$( echo "$tool_url_path"  | cut -d "@" -f 2 )

            # path to where the tool will be cloned
            path=$( echo "$tool_url_path" | cut -d "@" -f 3 )
            
            if [[ -e $path ]];then
                log_msg "$tool already installed"
                continue
            fi

            # installation for exploitdb
            log_msg "installing $tool"
            if [[ $tool = "exploitdb" ]];then
                if ! [[ -d $path ]];then
                    sudo git clone $url $path
                    sudo ln -sf /opt/exploit-database/searchsploit /usr/local/bin/searchsploit
                    cp -n /opt/exploit-database/.searchsploit_rc ~/
                fi
            elif [[ $tool = "linpeas.sh" ]];then
                mkdir -p $path
                curl -L "$url" > $path/linpeas.sh
            elif [[ $tool = "rtl8812au" ]];then
                git clone $url $path
                # execute compilation process here...
            else
                git clone $url $path
            fi
        done
    }

    # tools categories here, add or delete tools if needed
    programming_tools=( python3 python3-venv python3-pip emacs git gdb )
    virtualization_tools=( qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager )
    container_tools=( docker.io docker-compose )
    system_tools=( build-essential terminator conky-all neofetch htop tree openssh-server )
    network_analysis_tools=( wireshark netdiscover  )
    network_security_tools=( aircrack-ng reaver bettercap )
    radio_tools=( gnuradio gqrx-sdr rtl-sdr )
    web_security_tools=( wfuzz sqlmap )
    anonymity_tools=( tor torbrowser-launcher proxychains4 macchanger )
    cracking_tools=( hydra john hashcat hashcat-nvidia hcxtools crunch )
    malware_detection_tools=( rkhunter chkrootkit clamav )
    github_tools=(
        exploitdb@https://gitlab.com/exploit-database/exploitdb.git@/opt/exploit-database
        webToolkit@https://github.com/mind2hex/webtoolkit@${github_dir}/my_tools/webToolkit
        NetRunner@https://github.com/mind2hex/NetRunner@${github_dir}/my_tools/NetRuner
        TCPCobra@https://github.com/mind2hex/TCPCobra@${github_dir}/my_tools/TCPCobra
        Hackpack_usb@https://github.com/mind2hex/Hackpack_usb@${github_dir}/my_tools/Hackpack_usb
        linpeas.sh@https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh@${github_dir}/cloned_tools/LinPeas/linpeas.sh
        rtl8812au@https://github.com/aircrack-ng/rtl8812au.git@${github_dir}/cloned_tools/rtl8812au
    )

    tools=( ${programming_tools[@]} )
    install_tools_with_pkg_manager "programming_tools"
    if [[ "${choice}" = "y" ]];then
        # tools configuration here
	    # python3 libraries installation here
        echo -n ""
    fi

    tools=( ${virtualization_tools[@]} )
    install_tools_with_pkg_manager "virtualization_tools"
    if [[ "${choice}" = "y" ]];then
        # tools configuration here
        # add user to libvirt group to manage virtual machines without root permissions
        sudo adduser $(whoami) libvirt
        sudo adduser $(whoami) kvm
    fi
    
    tools=( ${container_tools[@]} )    
    install_tools_with_pkg_manager "container_tools"
    if [[ "${choice}" = "y" ]];then
        # tools configuration here
        echo -n ""
    fi

    tools=( ${system_tools[@]} )
    install_tools_with_pkg_manager "system_tools"    
    if [[ "${choice}" = "y" ]];then
        # conky configuration
        mkdir -p ${HOME}/.config/conky/
        cp ./conky.conf ${HOME}/.config/conky/

        # neofetch configuration
        if [[ -z $( grep -m 1 -o "neofetch" ~/.bashrc ) ]];then
            echo -e "\nneofetch" >> ~/.bashrc
        fi
    fi

    tools=( ${network_analysis_tools[@]} )
    install_tools_with_pkg_manager "network_analysis_tools"
    if [[ "${choice}" = "y" ]];then
        # tools configuration here
        echo -n ""
    fi
    
    tools=( ${network_security_tools[@]} )
    install_tools_with_pkg_manager "network_security_tools"
    if [[ "${choice}" = "y" ]];then
        # tools configuration here
        echo -n ""
    fi

    tools=( ${radio_tools[@]} )
    install_tools_with_pkg_manager "radio_tools"
    if [[ "${choice}" = "y" ]];then
        # tools configuration here
        echo -n ""
    fi
    
    tools=( ${web_security_tools[@]} )
    install_tools_with_pkg_manager "web_security_tools"
    if [[ "${choice}" = "y" ]];then
        # tools configuration here
        echo -n ""
    fi
    
    tools=( ${anonymity_tools[@]} )
    install_tools_with_pkg_manager "anonymity_tools"
    if [[ "${choice}" = "y" ]];then
        # tools configuration here
        echo -n ""
    fi
    
    tools=( ${cracking_tools[@]} )
    install_tools_with_pkg_manager "cracking_tools"
    if [[ "${choice}" = "y" ]];then
        # tools configuration here
        echo -n ""
    fi
    
    tools=( ${malware_detection_tools[@]} )
    install_tools_with_pkg_manager "malware_detection_tools"
    if [[ "${choice}" = "y" ]];then
        # tools configuration here
        echo -n ""
    fi

    install_tools_from_github

    # extern tools resources:
    # code (visualstudiocode) https://code.visualstudio.com/
    # nmap https://nmap.org/
    # kismet https://www.kismetwireless.net/packages/
    # gobuster https://github.com/OJ/gobuster
    # bettercap https://www.bettercap.org/
    # hackrf tools https://github.com/greatscottgadgets/hackrf.git
}

install_wordlists(){
    wordlist=(
        SecLists@https://github.com/danielmiessler/SecLists@${wordlist_dir}/SecLists
        rockyou.txt@https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt@${wordlist_dir}/rockyou.txt
    )

    for wordlist_url_path in ${wordlist[@]};do
        # wordlist name
        wordlist=$( echo "${wordlist_url_path}" | cut -d "@" -f 1 )

        # url to the github wordlist
        url=$( echo "${wordlist_url_path}" | cut -d "@" -f 2 )

        # path to the destination of the wordlist
        path=$( echo "${wordlist_url_path}" | cut -d "@" -f 3 )

        # checking if wordlist is already installed
        if [[ -f ${path} ]];then
            continue
        fi

        log_msg "Installing $wordlist to $path"
        if [[ $wordlist = "rockyou.txt" ]];then
            sudo wget "$url" -O "$path"
        else
            sudo git clone $url $path
        fi
    done
}

additional_configurations(){
    log_msg "Copying ./bash_aliases to ~/.bash_aliases"
    cp ./bash_aliases ~/.bash_aliases
    if [[ -z $( grep ". ~/.bash_aliases" ~/.bashrc ) ]];then
        echo -e "\n. ~/.bash_aliases" >> ~/.bashrc
    fi

    log_msg "Copying ./bash_functions to ~/.bash_functions"
    cp ./bash_functions ~/.bash_functions
    if [[ -z $( grep -o ". ~/.bash_functions" ~/.bashrc ) ]];then
        echo -e "\n. ~/.bash_functions" >> ~/.bashrc
    fi

    log_msg "Adding wifi pineapple address to /etc/hosts"
    wifi_pineapple_addr="172.16.42.1"
    hosts=$( grep -o "${wifi_pineapple_addr}" /etc/hosts )
    if [[ -z "${hosts}" ]];then
	    echo -e "172.16.42.1\twifi-pineapple.net\t# port 1471" | sudo tee -a /etc/hosts > /dev/null
    fi
}

main (){
    # request sudo rights password
    sudo whoami > /dev/null
    detect_package_manager
    update_upgrade    
    setup_directories
    install_tools
    install_wordlists
    additional_configurations

    exit 0
}

main 

# add ngrok to tools
#  curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list && sudo apt update && sudo apt install ngrok