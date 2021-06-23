# Usb_PA_to0lkit

To0lkit for quick info gathering from USB.

## Description

Some bash/powershell/python scripts to store inside an USB and execute once you gain physic access to a machine.

## Getting Started
### To check first
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
python --version
``` 




