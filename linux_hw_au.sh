#!/bin/bash
#Shilov 2015
#v.0.1.5 esxi fields + hw_vendor fix #v.0.1.4 adjustments for A.Fedonov #v.0.1.3 Inventory file introduced #v.0.1.1 new GIT versioning #ver 2.8.7 fix for runuser #ver 2.8.6 smal fix #ver 2.8.5 Templates introduced #ver 2.8.4 new storge IBM 5k and backyp-gw #2.8.3.3 output conveyor fixed #2.8.2 +WL, UP and java ver. #fix for LNX6.9 oracle version #2.8 WA for new hosts&sy #v.2.7 02.06.2020 +kernel +ulimits +nic_drivers +component version, fixed: ora_ver for ballenger&langley #v2.6 14.01.2020: +HP Gen10 support +TimesTen version #v2.5 22.08.2019: + HDD Size and Model. #v2.4 21.08.2019: + Oracle ver. #v2.3 22.03.2019: + HW SNs. #v2.2 20.03.2018: CPU cores + threads fix. VMVARE HW_TYPE support.
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
    printf "#$site_id INVENTORY FILE\n#V.01\n#Used to run HW INVENTORY AUDIT\n\n### UPM/OAM ###\n256.256.256.256 upm1a_example\n256.256.256.257 upmdb1a_example\n256.256.256.258 oam1a_example\n\n### SDP ###\n256.256.256.259 sdp10a #lnxsdp\n256.256.256.260 sdp13a #aixsdp\n\n### RCS ###\n\n### SGU ###\n\n### SLU ###\n\n### OSA ###\n\n### ECI ###\n\n### NOTIF ###\n\n### OFR ###\n\n### SAPI/AJMS/FEADMIN ###\n\n### DTR ###\n\n### SYSRV ###\n\n### NASGW ###\n\n### VCENTER ###\n256.256.256.261 VCENTER vcenter\n256.256.256.262 vp-x86-esxi-1\n\n### CISCO JUNIPER ARUBA ###\n\n### LBA ###\n\n### MAU ###\n\n### OTHER ###\n\n" > inventory.$site_id
    exit;
fi

printf "SITE|HOSTNAME|IP ADDR|ROUTE|HW VENDOR|HW TYPE|HW SN|LNX SCORE|KERNEL|HW ARCH|APP VERSION|APP INSTALL DATE(M/D/Y)|UP VERSION|ORA CLIENT|ORA DB|TT DB|WL VERSION|JAVA VER|RAM (KB)|PHYSICAL CPUS|CORES|THREADS|CPU MODEL|HDD SIZE|HDD MODEL|HDD HEALTH|ACTIVE UEFI BANK|UEFI/BIOS VERSION|FILE-MAX (sysctl.conf)|FILE-LIMIT (ulimit -n)|UPTIME|NIC DRVs|EMC MODEL|EMC SERIAL|EMC FLARE|V7k MODEL|V7k TYPE|V7k ENCLOSURE SN|v7K FW|V7k failed HDDs|V7k CONSOLE|V5k MODEL|V5k TYPE|V5k ENCLOSURE SN|v5K FW|V5k failed HDDs|V5k CONSOLE|DD MODEL|DD SERIAL|DD OS|DD DISK STATUS|DD UPTIME|HOSTED VMs\n";

# GENERAL LOOP
for host in $(grep -iE $host_match $inventory_file|grep -viE "$lnx_ex_tmplt"|awk {'print$1'}|sort|uniq);
do ping -c1 -W1 $host 1> /dev/null && printf "$site_id|" && ssh -q $host "
	hw_type=\`version 2>/dev/null | grep -i hw_type | awk '{print \$2}'\`;
	hostik=\`hostname\`;
	ip_addr=\`grep -i \$hostik /etc/hosts | awk '{print \$1}' | tail -1\`;
	routes=\`ip r | grep default | awk '{print \$3}'\`;
	score=\`version 2>/dev/null | grep -i lnx_score | awk '{print\$2}'| tr -d '\n'\`;
	our_kernel=\`uname -r|tr -d '\n'\`;
	hw_arch=\`version 2>/dev/null | grep -i HW_ARCH | awk '{print\$2}'| tr -d '\n'\`;
	app_version_date=\`rpm -qa --qf '%{VERSION}| %{INSTALLTIME:day}| %{NAME}\n' | grep -E 'CBS|sgu' | grep -vE 'Age|RIP|PERL|DBC|sguconf' | sort | tail -1 | awk -F '|' '{print\$1\"|\"\$2}'| tr -d '\n'\`;
	up_version=\`grep -i wrapper.java.additional.4= /home/jboss/conf/wrapper.conf 2>/dev/null| awk -F '=' '{print \$3}'\`;
	orac_ver=\`runuser -l oracle 'sqlplus -V 2>/dev/null' 2>/dev/null| awk '{ print \$3}'|tr -d '\n'\`;
	wl_version=\`source ~/.bash_profile; grep -i Server \$BEA_HOME/registry.xml 2>/dev/null | grep version | awk -F '\"' '{print \$4}'|tr -d '\n'\`;
	java_version=\`java -version 2>&1|head -n 1| awk '{print \$3}' |tr -d '\"'|tr -d '\n'\`;
	ram=\`free | grep -i mem | awk '{print\$2}'\`;
	phy_c_count=\`dmidecode -t 4 |grep -i 'core count:'|wc -l|tr -d '\n'\`;
	c_cores=\`egrep -E '^physical|core id' /proc/cpuinfo| xargs -l2 | sort -u | uniq | wc -l| tr -d '\n'\`;
	c_threads=\`grep -i 'processor' /proc/cpuinfo | sort -u | wc -l| tr -d '\n'\`;
	cpu_m=\`grep -i intel /proc/cpuinfo | grep -vE 'vendor_id|flags' | tail -1 | awk -F ':' '{print \$2}'| tr -d ' '|tr -d '\n'\`;
	max_files=\`grep fs.file /etc/sysctl.conf |grep -v '#'| awk -F [=] '{ print \$2}'|tr -d ' '|tr -d '\n'\`;
	file_limit=\`ulimit -n|tr -d '\n'\`;
	uptime=\`uptime | awk '{print \$3, \$4}'|tr -d ','\`;
	nic_drivers=\`modinfo bnx2 2>/dev/null|grep ^version|awk '{print \$2}'|tr '\n' ',';modinfo bnx2i 2>/dev/null|grep ^version|awk '{print \$2}'|tr '\n' ',';modinfo bnx2x 2>/dev/null|grep ^version|awk '{print \$2}'|tr -d '\n'\`;
	case \$hw_type in 
		IBM ) hdd_size=\`fdisk -l /dev/sda 2>/dev/null | grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; 
			  hdd_model=\`smartctl -a /dev/sda | grep 'Device:' | awk '{print \$2 \$3}'|tr -d '\n'\`; 
			  hdd_heal=\`smartctl -a /dev/sda | grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`;
			  cur_fw_bank=\`dmidecode 2>/dev/null | grep -i UEFI| grep Current | awk -F [-] '{print \$2}'| tr -d '\n'\`;
			  cur_fw=\`dmidecode 2>/dev/null | grep -i UEFI| grep \$cur_fw_bank 2>/dev/null | grep Ver | awk -F [[] '{print \$2}' | tr -d ']'| tr -d '\n'\`; 
			  r_hw_vendor=\`printf \"IBM\"\`; 
			  r_hw_type=\`dmidecode 2>/dev/null |grep -i BladeCenter | awk '{print \$3,\$4,\$5}'| tr -d '\n'\`;
			  r_hw_sn=\`dmidecode 2>/dev/null |grep -A3 -i BladeCenter| grep Serial | awk '{print \$3}'| tr -d '\n'\`;
				if [[ -z \$r_hw_type ]]; then 
					r_hw_type=\`dmidecode |grep -i 'IBM System x' | awk '{print \$3,\$4,\$5,\$6}'| tr -d '\n'\`; 
				fi; 
				if [[ -z \$r_hw_sn ]]; then 
					r_hw_sn=\`dmidecode |grep -A3 -i 'IBM System x'| grep Serial | awk '{print \$3}'| tr -d '\n'\`; 
				fi; 
		;; 
		VMWARE ) hdd_size=\`fdisk -l /dev/sda 2>/dev/null | grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; 
				 hdd_model=\`printf \"VMWARE NA\"\`; 
				 hdd_heal=\`printf \"Not Supported\"\`;
				 cur_fw_bank=\`printf \"VMWARE NA\"\`; 
				 cur_fw=\`printf \"VMWARE NA\"\`; 
				 r_hw_vendor=\`printf \"VM\"\`; 
				 r_hw_type=\`dmidecode | grep 'Product Name' | awk '{print \$3}'| tr -d '\n'\`; 
				 r_hw_sn=\`dmidecode | grep -A3 -i 'Product Name' | grep Serial | awk -F ':' '{print \$2}' |head -1| tr -d '\n'\`
		;; 
		Compaq ) r_hw_sn=\`dmidecode | grep -A3 -i 'Product Name' | grep Serial | awk '{print \$3}'| tr -d '\n'\`; 
				 cur_fw_bank=\`printf \"HP NA\"\`; 
				 cur_fw=\`dmidecode | grep -i 'Firmware Revision' | awk '{print \$3}'| tr -d '\n'\`; 
				 r_hw_vendor=\`printf \"HPE\"\`; 
				 r_hw_type=\`dmidecode | grep 'Product Name' | awk '{print \$3,\$4,\$5}'| tr -d '\n'\`; 
				 hdd_size=\`fdisk -l 2>/dev/null|grep -B80 Linux|grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; 
				 hdd_model=\`smartctl -a -d cciss,0 /dev/cciss/c0d0| grep 'Device:' | awk '{print \$2,\$3}'|tr -d '\n'\`;
				 hdd_heal=\`smartctl -a -d cciss,0 /dev/cciss/c0d0  2>/dev/null| grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`;
				 	if [[ -z \$hdd_model ]]; then 
				 		hdd_model=\`smartctl -a /dev/sda 2>/dev/null | grep 'Product:' | awk '{print \"HP\",\$2,\$3}'|tr -d '\n'\`; 
				 	fi; 
					 if [[ -z \$hdd_model ]]; then 
						hdd_model=\`smartctl -a /dev/sda 2>/dev/null| grep 'Device:' | awk '{print \"HP\",\$3,\$4}'|tr -d '\n'\`; 
					 fi;  
					 if [[ -z \$hdd_heal ]]; then 
						hdd_heal=\`smartctl -a /dev/sda 2>/dev/null| grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`; 
					 fi; 
		;;
		ProLiant ) r_hw_sn=\`dmidecode | grep -A3 -i 'Product Name' | grep Serial | awk '{print \$3}'| tr -d '\n'\`; 
				   cur_fw_bank=\`printf \"HP NA\"\`; 
				   cur_fw=\`dmidecode | grep -i 'Firmware Revision' | awk '{print \$3}'| tr -d '\n'\`; 
				   r_hw_vendor=\`printf \"HPE\"\`; 
				   r_hw_type=\`dmidecode | grep 'Product Name' | awk '{print \$3,\$4,\$5}'| tr -d '\n'\`; 
				   hdd_size=\`fdisk -l 2>/dev/null|grep -B80 Linux|grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; 
				   hdd_model=\`smartctl -a -d cciss,0 /dev/cciss/c0d0| grep 'Device:' | awk '{print \$2,\$3}'|tr -d '\n'\`;
				   hdd_heal=\`smartctl -a -d cciss,0 /dev/cciss/c0d0  2>/dev/null| grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`;
				   	if [[ -z \$hdd_model ]]; then 
				   		hdd_model=\`smartctl -a /dev/sda 2>/dev/null| grep 'Device:' | awk '{print \$2 \$3}'|tr -d '\n'\`; 
				  	fi; 
				  	if [[ -z \$hdd_heal ]]; then 
				   		hdd_heal=\`smartctl -a /dev/sda  2>/dev/null| grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`; 
				  	fi; 
		;;	
		HPE ) r_hw_sn=\`dmidecode | grep -A4 'System Information' | grep Serial | awk '{print \$3}'| tr -d '\n'\`; 
			  cur_fw_bank=\`printf \"HP NA\"\`;
			  cur_fw=\`printf \"FW: \";
			  dmidecode | grep -i 'Firmware Revision' | awk '{print \$3}'| tr -d '\n';printf \" BIOS: \";dmidecode | grep -i 'BIOS Rev' | awk '{print \$NF}'| tr -d '\n';\`;
			  r_hw_vendor=\`printf \"HPE\"\`; 
			  r_hw_type=\`dmidecode | grep -A4 'System Information' | grep 'Product Name' | awk '{print \$3,\$4,\$5}'| tr -d '\n'\`; 
			  hdd_size=\`fdisk -l 2>/dev/null|grep -B80 Linux|grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; 
			  hdd_model=\`smartctl -a -d cciss,0 /dev/cciss/c0d0| grep 'Device:' | awk '{print \$2,\$3}'|tr -d '\n'\`; 
			  hdd_heal=\`smartctl -a -d cciss,0 /dev/cciss/c0d0| grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`; 
			  	if [[ -z \$hdd_model ]]; then 
					hdd_model=\`smartctl -a /dev/sda | grep -E 'Vendor|Product' |awk '{print \$NF}' |tr '\n' ' '|tr -d '\n'\`; 
			  	fi; 
			  	if [[ -z \$hdd_heal ]]; then 
			  		hdd_heal=\`smartctl -a /dev/sda | grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`; 
			  	fi; 
		;;	
		LANGLEY4 ) runuser -l oracle8 '\$ORACLE_HOME/OPatch/opatch lsinventory' 2>/dev/null > /tmp/lnx_hw_au.txt; 
				   hdd_size=\`fdisk -l /dev/sda 2>/dev/null | grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; 
				   hdd_model=\`smartctl -a /dev/sda | grep 'Device:' | awk '{print \$2 \$3}'|tr -d '\n'\`; 
				   hdd_heal=\`smartctl -a /dev/sda | grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`;
				   cur_fw_bank=\`printf \"LANGLEY4 NA\"\`; 
				   cur_fw=\`dmidecode | grep -m 1 'Version:' | awk '{print \$2}'| tr -d '\n'\`; 
				   r_hw_vendor=\`printf \"INTEL\"\`; 
				   r_hw_type=\`printf 'INTEL LANGLEY4 '&& dmidecode | grep 'Product Name'| tail -1 | awk '{print \$3}'| tr -d '\n'\`;
				   r_hw_sn=\`dmidecode | grep -A3 -i 'Product Name'| head -3 | grep Serial | awk '{print \$3}'| tr -d '\n'\`;
		;; 
		BALLENGER ) runuser -l oracle8 '\$ORACLE_HOME/OPatch/opatch lsinventory' 2>/dev/null > /tmp/lnx_hw_au.txt; 
					hdd_size=\`fdisk -l /dev/sda 2>/dev/null | grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; 
					hdd_model=\`smartctl -a /dev/sda | grep 'Device:' | awk '{print \$2 \$3}'|tr -d '\n'\`; 
					hdd_heal=\`smartctl -a /dev/sda | grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`;
					cur_fw_bank=\`printf \"BALLENGER NA\"\`; 
					cur_fw=\`dmidecode | grep 'BIOS Revision' | awk '{print \$3}'| tr -d '\n'\`;
					r_hw_vendor=\`printf \"INTEL\"\`; 
					r_hw_type=\`printf 'INTEL BALLENGER '&&dmidecode | grep -m 1 'Product Name'| awk '{print \$3}'| tr -d '\n'\`;
					r_hw_sn=\`dmidecode | grep -A3 -i 'Product Name'| head -3 | grep Serial | awk '{print \$3}'| tr -d '\n'\`;
		;; 
		DPM3 ) hdd_size=\`fdisk -l /dev/sda 2>/dev/null | grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; 
			   hdd_model=\`smartctl -a /dev/sda | grep 'Device:' | awk '{print \$2 \$3}'|tr -d '\n'\`; 
			   hdd_heal=\`smartctl -a /dev/sda | grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`;
			   cur_fw_bank=\`printf \"DPM3 NA\"\`; 
			   cur_fw=\`dmidecode | grep -m 1 Version | awk '{print \$2}'| tr -d '\n'\`; 
			   r_hw_vendor=\`printf \"RadiSys\"\`;
			   r_hw_type=\`dmidecode | grep 'Product Name' | awk '{print \$4,\$3}'| tr -d '\n'\`;
			   r_hw_sn=\`printf \"See IPMI FRU\"\`;
		;; 
		DPM2 | DPM1 ) hdd_size=\`fdisk -l /dev/sda 2>/dev/null | grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; 
			   hdd_model=\`smartctl -a /dev/sda | grep 'Device:' | awk '{print \$2 \$3}'|tr -d '\n'\`;
			   hdd_heal=\`smartctl -a /dev/sda | grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`;
			   cur_fw_bank=\`printf \"DPM2 NA\"\`; 
			   cur_fw=\`printf \"DPM2 NA\"\`;
			   r_hw_vendor=\`printf \"RadiSys\"\`;
			   r_hw_type=\`printf \"DPM2\"\`;
			   r_hw_sn=\`printf \"DPM2\"\`;
		;; 
		* ) hdd_size=\`fdisk -l 2>/dev/null | grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`;
			hdd_model=\`smartctl -a /dev/sda 2>/dev/null | grep 'Device:' | awk '{print \$2 \$3}'|tr -d '\n'\`;
			hdd_heal=\`smartctl -a /dev/sda 2>/dev/null | grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`;
			cur_fw_bank=\`printf \"NA\"\`;
			cur_fw=\`printf \"NA\"\`;
			r_hw_vendor=\`printf \"NA\"\`;
			r_hw_type=\`printf \"NA\"\`;
			r_hw_sn=\`printf \"NA\"\`;
		;; 
	esac
	if [ ! -f /tmp/lnx_hw_au.txt ]; then 
		runuser -l oracle '\$ORACLE_HOME/OPatch/opatch lsinventory' 2>/dev/null > /tmp/lnx_hw_au.txt; 
		runuser -l ttuser -c '\$TT_HOME/bin/ttadmin -version' 2>/dev/null >> /tmp/lnx_hw_au.txt; 
	fi
	orad_ver=\`grep Database /tmp/lnx_hw_au.txt |tail -1 | awk '{print \$NF}'|tr -d '\"'|tr -d '\n'\`;
	tt_ver=\`grep TimesTen /tmp/lnx_hw_au.txt |tail -1 | awk '{print \$NF}'|tr -d '\n'\`;
	case \$hostik in 
		upm1 | upm2 ) hw_arch=\`printf \"i686\"\`; 
					  /opt/Navisphere/bin/navicli -h emc1 getagent > /tmp/navi_agent.txt 2>/dev/null; 
					  emc=\`grep Model: /tmp/navi_agent.txt | awk '{print \$2}'| tr -d '\n'; printf ' |'; grep No: /tmp/navi_agent.txt | awk '{print \$3}'| tr -d '\n'; printf ' |'; grep Revision: /tmp/navi_agent.txt | awk '{print \$2}'| tr -d '\n';\`;
		;; 
		oam1 ) v7k=\`ssh superuser@nas_console 'lssystem' | grep product_name| awk '{print \$2, \$3, \$4}'| tr -d '\n';printf ' |';ssh superuser@nas_console 'lsenclosure' | grep io_grp| awk '{print \$3, \$7}' | tr '\n' ' ';printf ' |';ssh superuser@nas_console 'lsenclosure' | grep io_grp| awk '{print \$3, \$8}' | tr '\n' ' ';printf ' |';ssh superuser@nas_console 'lssystem' | grep code_level| awk '{print \$2}'| tr -d '\n';printf ' |';ssh superuser@nas_console 'lsdrive' | grep failed| wc -l | tr '\n' ' ';printf ' |';ssh superuser@nas_console 'lssystem' | grep console_IP| awk '{print \$2}'| tr -d '\n'\`;
		;; 
		oam2 ) v7k=\`printf \"same as node1|same as node1|same as node1|same as node1|same as node1\"\`;
		;; 
		upmdb* ) hdd_size=\`fdisk -l /dev/sda 2>/dev/null | grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; 
				 dd=\`ssh -q sysadmin@dd 'system show modelno' | awk '{print \$3}'| tr -d '\n';printf ' |';ssh -q sysadmin@dd 'system show serialno' | awk '{print \$3}'| tr -d '\n';printf ' |';ssh -q sysadmin@dd 'system show version' | awk '{print \$4}'| tr -d '\n';printf ' |';ssh -q sysadmin@dd 'disk status' | grep oper | awk '{print \$1}'| tr -d '\n';printf ' |';ssh -q sysadmin@dd 'system show uptime' | grep load | awk '{print \$3, \$4}'| tr -d '\n'| tr -d ','\`;
		;; 
		backup-gw1a ) hdd_size=\`fdisk -l /dev/sda 2>/dev/null | grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; 
					  v7k=\`ssh superuser@san_console 'lssystem' | grep product_name| awk '{print \$2, \$3, \$4}'| tr -d '\n';printf ' |';ssh superuser@san_console 'lsenclosure' | grep io_grp| awk '{print \$3, \$7}' | tr '\n' ' ';printf ' |';ssh superuser@san_console 'lsenclosure' | grep io_grp| awk '{print \$3, \$8}' | tr '\n' ' ';printf ' |';ssh superuser@san_console 'lssystem' | grep code_level| awk '{print \$2}'| tr -d '\n';printf ' |';ssh superuser@san_console 'lsdrive' | grep failed| wc -l | tr '\n' ' ';printf ' |';ssh superuser@san_console 'lssystem' | grep console_IP| awk '{print \$2}'| tr -d '\n'\`; 
					  v5k=\`ssh superuser@san2_console 'lssystem' | grep product_name| awk '{print \$2, \$3, \$4}'| tr -d '\n';printf ' |';ssh superuser@san2_console 'lsenclosure' | grep io_grp| awk '{print \$3, \$7}' | tr '\n' ' ';printf ' |';ssh superuser@san2_console 'lsenclosure' | grep io_grp| awk '{print \$3, \$8}' | tr '\n' ' ';printf ' |';ssh superuser@san2_console 'lssystem' | grep code_level| awk '{print \$2}'| tr -d '\n';printf ' |';ssh superuser@san2_console 'lsdrive' | grep failed| wc -l | tr '\n' ' ';printf ' |';ssh superuser@san2_console 'lssystem' | grep console_IP| awk '{print \$2}'| tr -d '\n'\`;
		;; 
		backup-gw1b ) hdd_size=\`fdisk -l /dev/sda 2>/dev/null | grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; 
					  v7k=\`printf \"same as node1|same as node1|same as node1|same as node1|same as node1\"\`; v5k=\`printf \"same as node1|same as node1|same as node1|same as node1|same as node1\"\`;
		;; 
		* ) emc=\`printf \"NA|NA|NA\"\`; 
			v7k=\`printf \"NA|NA|NA|NA|NA|NA\"\`; 
			dd=\`printf \"NA|NA|NA|NA|NA\"\`; 
			v5k=\`printf \"NA|NA|NA|NA|NA|NA\"\`;
		;; 
	esac
	if [[ -z \$hw_type ]]; then hw_type=\`printf \"NA\"\`; fi
	if [[ -z \$hw_arch ]]; then hw_arch=\`printf \"NA\"\`; fi
	if [[ -z \$score ]]; then score=\`printf \"NA\"\`; fi
	if [[ -z \$orac_ver ]]; then orac_ver=\`printf \"NA\"\`; fi
	if [[ -z \$orad_ver ]]; then orad_ver=\`printf \"NA\"\`; fi
	if [[ -z \$hdd_size ]]; then hdd_size=\`fdisk -l | grep Disk | grep bytes | awk '{print \$3 \$4}'| tr -d '\n' |sed 's/.\$//'\`; fi
	if [[ -z \$hdd_heal ]]; then hdd_heal=\`printf \"NA\"\`; fi
	if [[ -z \$java_version ]]; then java_version=\`printf \"NA\"\`; fi
	if [[ -z \$up_version ]]; then up_version=\`printf \"NA\"\`; fi
	if [[ -z \$wl_version ]]; then wl_version=\`printf \"NA\"\`; fi
	if [[ -z \$tt_ver ]]; then tt_ver=\`printf \"NA\"\`; fi
	if [[ -z \$core_enabled ]]; then core_enabled=\`printf \"NA\"\`; fi
	if [[ -z \$app_version_date ]]; then app_version_date=\`printf \"NA|NA\"\`; fi
	if [[ -z \$v5k ]]; then v5k=\`printf \"NA|NA|NA|NA|NA|NA\"\`; fi
	if [[ -z \$dd ]]; then dd=\`printf \"NA|NA|NA|NA|NA\"\`; fi
	if [[ -z \$v7k ]]; then v7k=\`printf \"NA|NA|NA|NA|NA|NA\"\`; fi
	if [[ -z \$emc ]]; then emc=\`printf \"NA|NA|NA\"\`; fi
	if [[ -z \$cur_fw_bank ]]; then cur_fw_bank=\`printf \"NA\"\`; fi
	if [[ -z \$cur_fw ]]; then cur_fw=\`printf \"NA\"\`; fi
	printf \"\$hostik|\$ip_addr|\$routes|\$r_hw_vendor|\$r_hw_type|\$r_hw_sn|\$score|\$our_kernel|\$hw_arch|\$app_version_date|\$up_version|\$orac_ver|\$orad_ver|\$tt_ver|\$wl_version|\$java_version|\$ram|\$phy_c_count|\$c_cores|\$c_threads|\$cpu_m|\$hdd_size|\$hdd_model|\$hdd_heal|\$cur_fw_bank|\$cur_fw|\$max_files|\$file_limit|\$uptime|\$nic_drivers|\$emc|\$v7k|\$v5k|\$dd|NA\";";
	printf "\n";
done;
#Thats all folks!