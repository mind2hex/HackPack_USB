#!/bin/bash
# script to downloads tools and create directory structure for working.


echo "---------------------------------------------------"
echo -e "\n[!] \e[0;33m Initial update && upgrade \e[0m"
sudo apt-get update && sudo apt-get upgrade

general_use_tools=(
    docker.io docker-compose terminator conky-all neofetch
)
programming_tools=(
    python3 python3-venv python3-pip emacs gdb git code
)
network_hacking_tools=(
    nmap reaver wifite aircrack-ng  gnuradio wireshark gqrx-sdr
)
anonymizing_tools=(
    tor torbrowser-launcher proxychains4 macchanger
)

echo "---------------------------------------------------"
echo -e "\n[!] \e[0;33m Installing general use tools: ${general_use_tools[@]} \e[0m"
sudo apt install ${general_use_tools[@]}

echo "---------------------------------------------------"
echo -e "\n[!] \e[0;33m Installing programming tools: ${programming_tools[@]} \e[0m"
sudo apt install ${programming_tools[@]}

echo "---------------------------------------------------"
echo -e "\n[!] \e[0;33m Installing network hacking tools: ${programming_tools[@]} \e[0m"
sudo apt install ${network_hacking_tools[@]}

echo "---------------------------------------------------"
echo -e "\n[!] \e[0;33m Installing anonymizing tools: ${anonymizing_tools[@]} \e[0m"
sudo apt install ${anonymizing_tools[@]}

## CONFIGURING SHELL PROFILE
cp ./profile ~/.profile
echo -e "\nsource ~/.profile" >> ~/.bashrc

## INSTALLING EXPLOITDB
sudo git clone https://gitlab.com/exploit-database/exploitdb.git /opt/exploit-database

## CONFIGURING CONKY
echo -e "\n[!] \e[0;33m configuring conky \e[0m"
mkdir -p ~/.config/conky/
cp ./conky.conf ~/.config/conky/

## PROGRAMMING DIRECTORIES
echo -e "\n[!] \e[0;33m creating programming directories in home dir\e[0m"
if [[ -d ${HOME}/Documents ]];then
  document_path="${HOME}/Documents"
else
  document_path="${HOME}/Documentos"
fi
mkdir -p ${document_path}/dev/python
mkdir -p ${document_path}/dev/c++
mkdir -p ${document_path}/dev/c

## CLONNING MY TOOLS
echo -e "\n[!] \e[0;33m Cloning git tools\e[0m" 
mkdir -p ${document_path}/github/my_tools
git clone https://github.com/mind2hex/webToolkit ${document_path}/github/my_tools/webToolkit
git clone https://github.com/mind2hex/NetRunner ${document_path}/github/my_tools/NetRunner
git clone https://github.com/mind2hex/TCPCobra  ${document_path}/github/my_tools/TCPCobra
git clone https://github.com/mind2hex/HackPack_USB  ${document_path}/github/my_tools/HackPack_USB

