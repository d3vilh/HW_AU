#!/bin/bash
#Shilov 2017. JUNIPER HW AUDIT
#v.1.1 FPC fix. 21.01.2019 #v1.0 25.10.2017
delat_krasivo=$1; site_name=KHB;
printf "SITE |HOSTNAME |MODEL |CHASIS SERIAL |CPU |MEMORY |BASE OS VERSION |BOOT FROM |UPTIME |NUM OF SYSTEM ALARMS |NUM OF CHASSIS ALARMS\n";
for host in $(grep -iE $delat_krasivo /etc/hosts|grep -viE '^ *#|farm|nortel|cajun|cluster|zbx|cisco|ure|sdp|ilo|not|shutdown|rctu|trsu'|awk {'print$2'}|sort|uniq);
do ping -c1 $host 1> /dev/null && 
fpcq=`ssh -q audit@$host "show chassis hardware | match FPC | match REV"|wc -l`; ((fpcq=fpcq-1));
dwa=0; uptime=''; chasis_sn=''; memory=''; cpu=''; base_os=''; boot_from='';
hostik=`ssh -q audit@$host "show version member 0| match Hostname" | awk '{print $2}' | tail -1| tr -d '\n'`;
model=`ssh -q audit@$host "show version member 0| match Model" | awk '{print $2}' | tail -1| tr -d '\n'`;
num_system_alarms=`ssh -q audit@$host "show system alarms | except larm " | wc -l| tr -d '\n'`;
num_chassis_alarms=`ssh -q audit@$host "show chassis alarms | except larm " | wc -l| tr -d '\n'`;
while [[ $dwa -le $fpcq ]]; do 
	uptime="$uptime`printf "fpc$dwa:";ssh -q audit@$host "show system uptime member $dwa | match load"|awk '{print $3,$4}'|tr -d ','| tr -d '\n';printf " ";`"; 
	chasis_sn="$chasis_sn`printf "fpc$dwa: ";ssh -q audit@$host "show chassis hardware | match \\"FPC $dwa \\"" | awk '{print $6}' | tr -d '\n';printf " ";`";
	memory="$memory`printf "fpc$dwa: "; ssh -q audit@$host "show system boot-messages member $dwa | match real |except port" | awk '{print $4}'|tr -d ','| tr -d '\n';printf " ";`";
	cpu="$cpu`printf "fpc$dwa: "; ssh -q audit@$host "show system boot-messages member $dwa| match cpu"|head -1 | awk -F '[:]' '{print $2}'| tr -d '\n';printf " ";`"; 
	base_os="$base_os`printf "fpc$dwa: "; ssh -q audit@$host "show version member $dwa | match Junos:" | awk '{print $2}'| tr -d '\n';printf " ";`";
	boot_from="$boot_from`printf "fpc$dwa: "; ssh -q audit@$host "show system storage partitions member $dwa | match Current" | awk '{print $4,$5}'| tr -d '\n';printf " ";`";
	let dwa=dwa+1; 
done
printf "$site_name |$hostik |$model |$chasis_sn |$cpu |$memory |$base_os |$boot_from |$uptime |$num_system_alarms |$num_chassis_alarms \n";
done;
# Known issues:
# Junos 12.3R4.6 not compatible for Junos $base_os version get
# QFX switches returns "not valid not valid" for $boot_from - this is normal
# If script does not retrieve all the vars - set system services ssh rate-limit to 50 on your Juniper