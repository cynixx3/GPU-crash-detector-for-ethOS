# GPU Crash Detector for ethOS (by cYnIxX3 http://thecynix.com/scripts-for-ethos/)
This script will monitor individual GPU's on ethOS mining rigs, regardless of the miner program, and automatically log any issues when they happen and every hour. It will also check the ethOS config (remote or local) for "autoreboot #" and if the number is less than the current number of reboots the system will restart. 

## Installation
`source <(curl -s https://raw.githubusercontent.com/cynixx3/GPU-crash-detector-for-ethOS/master/gpu-install.txt)`

## Update
To update the script simply run.
`wget https://raw.githubusercontent.com/cynixx3/GPU-crash-detector-for-ethOS/master/gpu.sh -O /home/ethos/gpu.sh`

## View the Log
This script keeps a log of all GPU crashes, you can view the log with
`tail /home/ethos/crash.log`

## Manual run
You can test the installation with the command
`./gpu.sh` (note: it will run every 5 minutes after install.)


## CONFIGURATION 
Defaults:
```logsize="100"   # Set the number of lines to keep in the log
loggood="false" # Set "true" if you want an hourly log of success
crashspeed="0"  # Set the per gpu hash rate that will trigger a crash condition
minuptime="21600" # Set the number in seconds the script should wait after start before rebooting```

21600 seconds is 6 hours. This is set high to prevent poorly built rigs from having too high of a fire risk. If your rig is built really well and you know the reason for the gpu crashes, you could lower this though its not recommended. 

You can change any of the above in gpu.sh to fit your needs. 

**!!!!!WARNING!!!!!** 
This is not an official EthOS script. It is not supported anywhere. You use this script at your own risk. There is a reason EthOS does not include these self regulating reboots. Be sure you have a well built rig.

BY USING THE REBOOT FEATURE IN **ANY** SCRIPT YOU ARE BYPASSING ethOS SAFEGARDS WHICH CAN RESULT IN YOUR MINER CATCHING ON FIRE! You have been notified.

## Auto rebooting from a crashed GPU
If you set "autoreboot 5" or any number in local.conf this sript will reboot your miner. With this setting the miner will reboot when a gpu meets the crash condition in the configuration above, where 5 is the number of times it will reboot before waiting for inspection. When the miner reboots the number of times you set it will start up not mining so you have a chance to fix the problem.

It is recommended to keep this value low.

Once fixed run `clear-thermals` to reset count or `echo 0 > /opt/ethos/etc/autorebooted.file`

If you found this script useful please donate BitCoin to:
BTC 1G6DcU8GrK1JuXWEJ4CZL2cLyCT57r6en2
or Ethereum to:
ETH 0x42D23fC535af25babbbB0337Cf45dF8a54e43C37
