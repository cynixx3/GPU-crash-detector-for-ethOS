#!/bin/bash
#
# GPU Monitor and Restart Script for EthOS (by cYnIxX3)
#
# Version 1.3.1 
#
# INSTALL:  `source <(curl -s http://thecynix.com/gpu-install.txt)`
# UPDATE:   `wget http://thecynix.com/gpu.txt -O /home/ethos/gpu.sh`
# VIEW LOG: `tail /home/ethos/crash.log`
# RUN MANUALLY: `./gpu.sh` (note: it will run every 5 minutes after install.)
# 
# !!!!!WARNING!!!!! This is not an official EthOS script. It is not supported
# anywhere. You use this script at your own risk. There is a reason EthOS does
# not include these self regulating reboots. Be sure you have a well built rig.
#
# BY USING THE REBOOT FEATURE IN ANY SCRIPT YOU ARE BYPASSING ETHOS SAFEGARDS
# WHICH CAN RESULT IN YOUR MINER CATCHING ON FIRE!!!!!!!!!! 
#
# Set "autoreboot 5" in local.conf if you want this sript to reboot your miner
# Where 5 is the number of times it will reboot. Run `clear-thermals` to reset count.
# or "echo 0 > /opt/ethos/etc/autorebooted.file"
#
#####################################################################################
# If you found this script useful please donate BitCoin to:
# BTC 1G6DcU8GrK1JuXWEJ4CZL2cLyCT57r6en2
# or Ethereum to:
# ETH 0x42D23fC535af25babbbB0337Cf45dF8a54e43C37
#####################################################################################

# CONFIGURATION 

logsize="100"   # Set the number of lines to keep in the log
loggood="false" # Set "true" if you want an hourly log of success
crashspeed="0"  # Set the per gpu hash rate that will trigger a crash condition
minuptime="21600" # Set the number in seconds the script should wait after start before rebooting

# INFORMATION COLLECTION
uptime=$(sed 's/\..*//' /proc/uptime)
minersec=$(grep miner_secs: /var/run/ethos/stats.file | cut -d : -f 2)
updating=$(cat /var/run/ethos/updating.file)
allow=$(cat /opt/ethos/etc/allow.file)
throttled=$(cat /var/run/ethos/throttled.file)
oldIFS=$IFS IFS=" "
read -r -a selectedgpus <<< "$(/opt/ethos/sbin/ethos-readconf selectedgpus)"
read -r -a tempatures <<< "$(grep ^temp: /var/run/ethos/stats.file | cut -d : -f 2 | sed 's/\...//g')"
read -r -a memstates <<< "$(grep ^memstates: /var/run/ethos/stats.file | cut -d : -f 2)"
read -r -a powertunes <<< "$(grep ^powertune: /var/run/ethos/stats.file | cut -d : -f 2)"
read -r -a hashrates <<< "$(tail -1 /var/run/ethos/miner_hashes.file)"
IFS=$oldIFS
hostname=$(hostname)
loc=$(/opt/ethos/sbin/ethos-readconf loc)
DT=$(date +"%D %T")
jumpgpu=0
number='[1-9]'
autoreboot=$(/opt/ethos/sbin/ethos-readconf autoreboot)
rebcount=$(cat /opt/ethos/etc/autorebooted.file)
error=$(cat /var/run/ethos/status.file)
panelURL=$(cat /var/run/ethos/url.file)
if ping -q -c 1 -W 1 8.8.8.8 >/dev/null ; then
  net="true"
  json=$(curl -s "$panelURL"/?json=yes | sed 's/"},/"}\n/g' | grep "$hostname" | sed -e 's/^{"rigs"://' -e 's/[{"}]//g' -e 's/,/\n/g')
  if [[ $json == "" ]] ; then
    jcondition="Failing Panel Verification"
  else
    jcondition=$(printf "%s" "$json" | grep condition: | cut -d : -f 3)
  fi
else
  net="false"
fi

# LOG STUFF
touch /home/ethos/crash.log 
/bin/cp /home/ethos/crash.log /tmp/crash.log
/usr/bin/sudo /bin/chown ethos.ethos /home/ethos/crash.log /tmp/crash.log 
function f.truncatelog(){
  tail -n $logsize /tmp/crash.log > /home/ethos/crash.log
}
  
# BASIC RIG CHECKS
if [[ $uptime -lt $minuptime ]] \
|| [[ $minersec -lt "300" ]]; then
  if [[ $(date +"%M") == "00" ]] || [ -t 1 ] ; then  
    echo "$loc has not tried mining long enough $DT" | tee -a /tmp/crash.log
    f.truncatelog
  fi
  exit 2
elif [[ $updating -eq "1" ]]; then
  if [[ $(date +"%M") == "00" ]] || [ -t 1 ] ; then  
    echo "$loc miner is updating $DT" | tee -a /tmp/crash.log	
    f.truncatelog
  fi
  exit 3
elif [[ $allow -eq "0" ]]; then
  if [[ $(date +"%M") == "00" ]] || [ -t 1 ] ; then  
    echo "$loc is Disallowed by user command. Run \'allow\' to start mining $DT" | tee -a /tmp/crash.log
    f.truncatelog
  fi
  exit 5
elif [[ $net == "false" ]] ; then
  if [[ $(date +"%M") == "00" ]] || [ -t 1 ] ; then  
    echo "$loc No internet connection $DT" | tee -a /tmp/crash.log
    f.truncatelog
  fi
  exit 7
elif [[ $throttled -eq "1" ]] ; then
  if [[ $(date +"%M") == "00" ]] || [ -t 1 ] ; then  
    echo "$loc has a GPU that overheated - http://ethosdistro.com/kb/#managing-temperature $DT" | tee -a /tmp/crash.log
    f.truncatelog
  fi
  exit 11
elif [[ $error = "hardware error: possible gpu/riser/power failure" ]] ; then
  if [[ $(date +"%M") == "00" ]] || [ -t 1 ] ; then  
    echo "$error - http://ethosdistro.com/kb/#adl $DT" | tee -a /tmp/crash.log
    f.truncatelog
  fi
  exit 13
fi

# MAIN GPU ERROR LOOP
for gpu in ${!hashrates[*]} ; do

# HARDWARE ERROR CHECKING (AKA FIRE PREVENTION CHECKS)	
if  [[ "${tempatures[gpu]}" == "511" ]] \
|| [[ "${powertunes[gpu]}" = "-1" ]] ; then
    if [[ $(date +"%M") == "00" ]] || [ -t 1 ] ; then
      echo "$loc - GPU$gpu may have a critical hardware problem that rebooting may not solve. $jcondition - $error$DT" | tee -a /tmp/crash.log
    fi
    continue
  fi
  if [[ "${selectedgpus[jumpgpu]}" > "$gpu" ]] ; then
    if [ -t 1 ] ; then
      echo "GPU$gpu is configured offine with the 'sel' config option - skipping checks on GPU$gpu"
    fi
    continue
  fi

# GPU CRASH DETECTION
  if [[ $error == "gpu crashed: reboot required" ]] \
|| [[ $error == "possible miner stall: check miner log" ]] \
|| [[ $(bc <<< "${hashrates[gpu]} <= $crashspeed") -eq "1" ]] ; then
    printf '%s GPU%s CRASHED %s\n -Status: %s - %s\n -Hashrate: %s\n -MemState: %s\n -PowerState: %s\n' "$loc" "$gpu" "$DT" "$jcondition" "$error" "${hashrates[*]}" "${memstates[*]}" "${powertunes[*]}"| tee -a /tmp/crash.log
    f.truncatelog
    if [[ $autoreboot =~ $number ]] && [[ $autoreboot -gt $rebcount ]] ; then
      ((rebcount++))
      echo $rebcount > /opt/ethos/etc/autorebooted.file
      /usr/bin/sudo /opt/ethos/bin/hard-reboot
    else
      echo "$loc has been rebooted too many times. Check why and run \'clear-thermals\' to reset $DT"
    fi
    exit 17
  fi
((jumpgpu++))
done

# GOOD LOGGING
if [[ $loggood == "true" && $(date +"%M") == "00" ]] || [ -t 1 ] ; then
  echo "$DT: $loc is $jcondition at $error" | tee -a /tmp/crash.log
  f.truncatelog
fi
