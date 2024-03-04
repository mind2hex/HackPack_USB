#!/bin/bash
# script to downloads tools and create directory structure for working.

echo -e "\n[!] \e[0;33m initial update && upgrade \e[0m"
sudo apt-get update && sudo apt-get upgrade

echo -e "\n[!] \e[0;33m installing tools \e[0m" 
tools=( \
	docker.io docker-compose \
	terminator emacs \
	python3 python3-venv python3-pip \
	git \
	conky-all
)
echo -e "--> ${tools[@]}"
sudo apt install ${tools[@]}

## CONFIGURING CONKY
echo -e "\n[!] \e[0;33m configuring conky \e[0m"
mkdir -p ~/.config/conky/
cp ./conky.conf ~/.config/conky/
####################nnnn

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
##########################

## GIT CLONE TOOLS
echo -e "\n[!] \e[0;33m Cloning git tools\e[0m" 
mkdir -p ${document_path}/github/my_tools
git clone https://github.com/mind2hex/webToolkit ${document_path}/github/my_tools/webToolkit
git clone https://github.com/mind2hex/NetRunner ${document_path}/github/my_tools/NetRunner
git clone https://github.com/mind2hex/TCPCobra  ${document_path}/github/my_tools/TCPCobra
git clone https://github.com/mind2hex/HackPack_USB  ${document_path}/github/my_tools/HackPack_USB
###################
