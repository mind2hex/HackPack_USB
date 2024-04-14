# HackPack_USB

Scripts to clone in a pendrive for pentesting purpose.

## Description

Some bash/powershell/python scripts to store inside a USB and execute once you gain physic access to a machine.

## Getting Started
### Check first
* Powershell: To be able to execute powershell scripts in Windows machines you need first to execute the following command in a powershell with administration privileges which changes the Execution Policy
```
Set-ExecutionPolicy RemoteSigned
```
* bash: To execute bash scripts in Linux machines you probably need to give execution permission to the scripts.
```
chomd u+x <script.sh>
```
* python: To execute python scripts you need to check if python is installed on the target machine first. You can do that with the following command from a terminal which will print the current version of you python installation.
```
python3 --version
``` 

## Current Structure
```
HackPack_USB
.
├── Linux
│   ├── environment_initialization
│   │   ├── conky.conf
│   │   ├── initialize_environment.sh
│   │   └── profile
│   └── scripts
│       ├── enumerate-process.sh
│       ├── enumerate-system.sh
│       ├── network-monitor.sh
│       ├── network-scan.sh
│       └── network-wap-scan.sh
└── Windows
```
## Linux
### environment_initialization
This directory contains the script `initialize_environment.sh` used to install automatically all tools i need to perform some security tasks. File `conky.conf` and `profile` are used by this script so don't touch it.

### scripts
This directory contains some useful bash scripts.
#### enumerate-process.sh
Simple process monitor that inspect all executed processess during a period of time.
#### enumerate-system.sh
Script to automatically enumerate system information and copy users files from `/home` folder to `./LOOT` folder.
#### network-monitor.sh
Script to inspect network devices. This script allow us to put devices in two different groups, one group for known devices and another group for unknown devices so we can figure when a new device (unknown) is connected to our network
#### network-scan.sh
Script to simply enumerate active hosts in the network specified. This script uses different tools commonly used in Linux distribution like ping, arping, etc.
#### network-wap-scan.sh
Script to scan near Access Points using a wireless interface.
