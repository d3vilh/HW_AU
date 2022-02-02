#!/bin/bash
#Shilov 2022 ESXi inventory audit. tested on ver 6.7
#v.0.1.5 busybox must die.
if [ ! -n "$1" ]; then 
	printf "\n Runs Hardware Inventory checks against any Linux-based servers.\n  Usage: ./linux_hw_au.sh HOSTNAME SITE_ID\n   Where:\n     HOSTNAME can be necessary server to run inventory on or mask for the group of hosts from the /etc/hosts\n   	 SITE_ID is optional parameter, will be inserted as first column of output. PROD_SITE is used by default\n  Examples:\n    ./linux_hw_au.sh sgu21b MSK\n    ./linux_hw_au.sh slu EKT\n    ./linux_hw_au.sh sgu23\n\n";
	exit; 
fi;

host_match=$1; # Hostname to run audit

lnx_ex_tmplt="MY_TEMPLATE";  # Template to exclude hosts from the /etc/hosts of your master node. i.e. grep -viE "template" /etc/hosts; its lnx_ex_tmplt="MY_TEMPLATE" by default.
if [ "$lnx_ex_tmplt" = "MY_TEMPLATE" ]; then 
	lnx_ex_tmplt="^ *#|audit_exclude|farm|blc|slu-dslu|amm|esm|admin|zbx|hsbu|_oob|_ilo|-om|-bb|rctu|cross|old|emc|fcs|_upm|ilo|upm_|vip|nas_console|_hsbn|_sw|-lba"; 
fi

site_id=$2; # SITE_ID for first column
if [ ! -n "$2" ]; then 
	site_id=PROD_SITE; 
fi

#File with hosts inventory. Can be /etc/hosts or similar, but sorted, wo duplicated entries.
inventory_file=inventory.$site_id 

if [ ! -e $inventory_file ] ; then
    printf ' Site inventory file is empty!\n Update Site inventory with necessary IP list and run audit again.\n'
    printf "#$site_id INVENTORY FILE\n#V.01\n#Used to run HW INVENTORY AUDIT\n\n### UPM/OAM ###\n256.256.256.256 upm1a_example\n256.256.256.257 upmdb1a_example\n256.256.256.258 oam1a_example\n\n### SDP ###\n256.256.256.259 sdp10a #lnxsdp\n256.256.256.260 sdp13a #aixsdp\n\n### RCS ###\n\n### SGU ###\n\n### SLU ###\n\n### OSA ###\n\n### ECI ###\n\n### NOTIF ###\n\n### OFR ###\n\n### SAPI/AJMS/FEADMIN ###\n\n### DTR ###\n\n### SYSRV ###\n\n### NASGW ###\n\n### VCENTER ###\n256.256.256.259 VCENTER vcenter\n256.256.256.260 vp-x86-esxi-1\n\n### CISCO JUNIPER ARUBA ###\n\n### LBA ###\n\n### MAU ###\n\n### OTHER ###\n\n" > inventory.$site_id
    exit;
fi

printf "SITE|HOSTNAME|IP ADDR|ROUTE|HW VENDOR|HW TYPE|HW SN|LNX SCORE|KERNEL|HW ARCH|APP VERSION|APP INSTALL DATE(M/D/Y)|UP VERSION|ORA CLIENT|ORA DB|TT DB|WL VERSION|JAVA VER|RAM (KB)|PHYSICAL CPUS|CORES|THREADS|CPU MODEL|HDD SIZE|HDD MODEL|HDD HEALTH|ACTIVE UEFI BANK|UEFI/BIOS VERSION|FILE-MAX (sysctl.conf)|FILE-LIMIT (ulimit -n)|UPTIME|NIC DRVs|EMC MODEL|EMC SERIAL|EMC FLARE|V7k MODEL|V7k TYPE|V7k ENCLOSURE SN|v7K FW|V7k failed HDDs|V7k CONSOLE|V5k MODEL|V5k TYPE|V5k ENCLOSURE SN|v5K FW|V5k failed HDDs|V5k CONSOLE|DD MODEL|DD SERIAL|DD OS|DD DISK STATUS|DD UPTIME|HOSTED VMs\n";

# GENERAL LOOP
for host in $(grep -iE $host_match $inventory_file|grep -viE "$lnx_ex_tmplt"|awk {'print$1'}|sort|uniq);
do ping -c1 -W1 $host 1> /dev/null && printf "$site_id|" && ssh -q $host "
	hostik=\`hostname\`;
	our_kernel=\`uname -sr\`;
	hw_arch=\`uname -i\`;
	ip_addr=\`grep -i \$hostik /etc/hosts | awk '{print \$1}' | tail -1\`;
	routes=\`esxcli network ip route ipv4 list | grep default | awk '{print\$3}'\`;
	score=\`esxcli system version get | grep -E 'Version|Update|Patch' | awk '{print\$2}'| od -c |awk -F '  ' '{print\$2\".\"\$4\".\"\$6\$8\$10\$11}'| head -1 | awk '{print\$1\$2\$3\" Upd:\"\$4\" Patch:\"\$5\$6}'\`;
	phy_c_count=\`esxcli hardware cpu global get | grep Packages | awk '{print \$3}'\`;
	c_cores=\`esxcli hardware cpu global get | grep Cores | awk '{print \$3}'\`;
	c_threads=\`esxcli hardware cpu global get | grep Threads | awk '{print \$3}'\`;    
    ram=\`esxcli hardware memory get | grep Physical | awk '{ a = \$3; rkb = a / 1000; print rkb}' OFMT='%1.0f'\`;
    app_version=\`esxcli software vib list | grep esx-base | awk '{print \$2}'\`;  
    app_date=\`esxcli software vib list | grep esx-base | awk '{print \$5}'\`;
    uptime=\`uptime | awk '{print \$3 \"days\"}'\`;	
	cpu_m=\`vim-cmd hostsvc/hostsummary | grep cpuModel | awk -F '\"' '{print \$2}'\`;
	file_limit=\`ulimit -n\`;
	r_hw_sn=\`esxcli hardware platform get | grep Serial | grep -v Enclosure | awk '{print\$3}'\`;
    r_hw_type=\`esxcli hardware platform get | grep 'Product' | awk -F ':' '{print\$2}' | awk '{print \$1,\$2,\$3}'\`; 
    r_hw_vendor=\`esxcli hardware platform get | grep 'Vendor' | awk '{print\$3}'\`; 
    hdd_size=\`esxcli storage core device list | grep -B1 Direct-Access | grep Size | awk '{ a = \$2; sgb = a / 953.674; print sgb\".0GB\"}'\`; 
    hdd_model=\`esxcli storage core device list | grep -A4 Direct-Access | grep Model | awk '{print \$2}'\`; 
    cur_fw=\`vim-cmd hostsvc/hosthardware | grep -A6 bios | grep -E 'Vers|major|minor' | awk '{print \$3}' | od -c | awk -F '   ' '{print\$3\$4\$5\".\"\$8\".\"\$10\$11}'| head -1\`; 
    hosted_vms=\`vim-cmd vmsvc/getallvms | grep vmx | awk '{print \$3\":\"\$2}'\`;
    [ -z \"\$hosted_vms\" ] && hosted_vms=\`printf \"Empty ESXi\"\`;
	printf \"\$hostik|\$ip_addr|\$routes|\$r_hw_vendor|\$r_hw_type|\$r_hw_sn|\$score|\$our_kernel|\$hw_arch|\$app_version|\$app_date|NA|NA|NA|NA|NA|NA|\$ram|\$phy_c_count|\$c_cores|\$c_threads|\$cpu_m|\$hdd_size|\$hdd_model|NA|NA|\$cur_fw|NA|\$file_limit|\$uptime|NA|NA|NA|NA|NA|NA|NA|NA|NA|NA|NA|NA|NA|NA|NA|NA|NA|NA|NA|NA|NA|\`echo \$hosted_vms\`\";";
	printf "\n";
done;
#    hosted_vms=\`esxcli vm process list | grep Display | awk '{print \$3}'\`;
#Thats all folks!