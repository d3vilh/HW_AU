#!/bin/bash
#Shilov 2015
#ver 2.8.4 new storge IBM 5k and backyp-gw #2.8.3.3 output conveyor fixed #2.8.2 +WL, UP and java ver. #fix for LNX6.9 oracle version #2.8 WA for new hosts&sy #v.2.7 02.06.2020 +kernel +ulimits +nic_drivers +component version, fixed: ora_ver for ballenger&langley #v2.6 14.01.2020: +HP Gen10 support +TimesTen version #v2.5 22.08.2019: + HDD Size and Model. #v2.4 21.08.2019: + Oracle ver. #v2.3 22.03.2019: + HW SNs. #v2.2 20.03.2018: CPU cores + threads fix. VMVARE HW_TYPE support.
if [ ! -n "$1" ]; then 
	printf "\n Runs Hardware Inventory checks against any Linux-based servers.\n  Usage: ./linux_hw_au.sh HOSTNAME SITE_ID\n   Where:\n     HOSTNAME can be necessary server to run inventory on or mask for the group of hosts from the /etc/hosts\n   	 SITE_ID is optional parameter, will be inserted as first column of output. PROD_SITE is used by default\n  Examples:\n    ./linux_hw_au.sh sgu21b MSK\n    ./linux_hw_au.sh slu EKT\n    ./linux_hw_au.sh sgu23\n\n";
	exit; 
fi;
delat_krasivo=$1
site_id=$2
if [ ! -n "$2" ]; then site_id=PROD_SITE; fi
printf "SITE |HOSTNAME |IP ADDR |ROUTE |HW TYPE |HW SN |LNX SCORE |KERNEL |HW ARCH |APP VERSION |APP INSTALL DATE(M/D/Y) |UP VERSION |ORA CLI |ORA DB |TT DB |WL VERSION |JAVA VER |RAM |CORES |THREADS |ENA CORES |CPU |HDD SIZE |HDD MODEL |HDD HEALTH |ACTIVE UEFI BANK |UEFI/BIOS VERSION |FILE-MAX (sysctl.conf) |FILE-LIMIT (ulimit -n)|UPTIME |NIC DRVs |EMC MODEL |EMC SERIAL |EMC FLARE |V7k MODEL |V7k TYPE |V7k ENCLOSURE SN |v7K FW |V7k failed HDDs |V7k CONSOLE |V5k MODEL |V5k TYPE |V5k ENCLOSURE SN |v5K FW |V5k failed HDDs |V5k CONSOLE |DD MODEL |DD SERIAL |DD OS |DD DISK STATUS |DD UPTIME \n";
for host in $(grep -iE $delat_krasivo /etc/hosts|grep -viE '^ *#|audit_exclude|farm|blc|slu-dslu|amm|esm|admin|zbx|hsbu|_oob|_ilo|-om|-bb|rctu|cross|old|emc|fcs|_upm|ilo|upm_|vip|nas_console|_hsbn|_sw|-lba'|awk {'print$2'}|sort|uniq);
do ping -c1 -W1 $host 1> /dev/null && printf "$site_id |" && ssh -q $host "
if [ ! -f /tmp/lnx_hw_au.txt ]; then runuser -l oracle '\$ORACLE_HOME/OPatch/opatch' lsinventory 2>/dev/null > /tmp/lnx_hw_au.txt; runuser -l ttuser -c '\$TT_HOME/bin/ttadmin -version' 2>/dev/null >> /tmp/lnx_hw_au.txt; fi
hostik=\`hostname\` 
ip_addr=\`grep -i \$hostik /etc/hosts | awk '{print \$1}' | tail -1\`
routes=\`ip r | grep default | awk '{print \$3}'\` 
hw_type=\`version 2>/dev/null | grep -i hw_type | awk '{print \$2}'\`
case \$hw_type in 
	IBM ) hdd_size=\`fdisk -l /dev/sda 2>/dev/null | grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; hdd_model=\`smartctl -a /dev/sda | grep 'Device:' | awk '{print \$2 \$3}'|tr -d '\n'\`; hdd_heal=\`smartctl -a /dev/sda | grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`;cur_fw_bank=\`dmidecode 2>/dev/null | grep -i UEFI| grep Current | awk -F [-] '{print \$2}'| tr -d '\n'\` cur_fw=\`dmidecode 2>/dev/null | grep -i UEFI| grep \$cur_fw_bank 2>/dev/null | grep Ver | awk -F [[] '{print \$2}' | tr -d ']'| tr -d '\n'\`; r_hw_type=\`dmidecode 2>/dev/null |grep -i BladeCenter | awk '{print \$3,\$4,\$5}'| tr -d '\n'\`;r_hw_sn=\`dmidecode 2>/dev/null |grep -A3 -i BladeCenter| grep Serial | awk '{print \$3}'| tr -d '\n'\`
			if [[ -z \$r_hw_type ]]; then r_hw_type=\`dmidecode |grep -i 'IBM System x' | awk '{print \$3,\$4,\$5,\$6}'| tr -d '\n'\`; fi; 
			if [[ -z \$r_hw_sn ]]; then r_hw_sn=\`dmidecode |grep -A3 -i 'IBM System x'| grep Serial | awk '{print \$3}'| tr -d '\n'\`; fi; ;; 
	VMWARE ) hdd_size=\`fdisk -l /dev/sda 2>/dev/null | grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; hdd_model=\`smartctl -a /dev/sda | grep 'Device:' | awk '{print \$2 \$3}'|tr -d '\n'\`; hdd_heal=\`printf \"Not Supported\"\`;cur_fw_bank=\`printf \"VMWARE NA\"\` cur_fw=\`dmidecode | grep -i 'Firmware Revision' | awk '{print \$3}'| tr -d '\n'\`; r_hw_type=\`dmidecode | grep 'Product Name' | awk '{print \$3}'| tr -d '\n'\`; r_hw_sn=\`dmidecode | grep -A3 -i 'Product Name' | grep Serial | awk -F ':' '{print \$2}' |head -1| tr -d '\n'\`;; 
	Compaq ) r_hw_sn=\`dmidecode | grep -A3 -i 'Product Name' | grep Serial | awk '{print \$3}'| tr -d '\n'\`; cur_fw_bank=\`printf \"HP NA\"\` cur_fw=\`dmidecode | grep -i 'Firmware Revision' | awk '{print \$3}'| tr -d '\n'\`; r_hw_type=\`dmidecode | grep 'Product Name' | awk '{print \$3,\$4,\$5}'| tr -d '\n'\`; 
		hdd_size=\`fdisk -l /dev/sda 2>/dev/null | grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; 
		hdd_model=\`smartctl -a -d cciss,0 /dev/cciss/c0d0| grep 'Device:' | awk '{print \$2,\$3}'|tr -d '\n'\`; 
			if [[ -z \$hdd_model ]]; then hdd_model=\`smartctl -a /dev/sda 2>/dev/null | grep 'Product:' | awk '{print \"HP\",\$2,\$3}'|tr -d '\n'\`; fi; 
			if [[ -z \$hdd_model ]]; then hdd_model=\`smartctl -a /dev/sda 2>/dev/null| grep 'Device:' | awk '{print \"HP\",\$3,\$4}'|tr -d '\n'\`; fi; 
		hdd_heal=\`smartctl -a -d cciss,0 /dev/cciss/c0d0  2>/dev/null| grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`; 
			if [[ -z \$hdd_heal ]]; then hdd_heal=\`smartctl -a /dev/sda 2>/dev/null| grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`; fi; ;;
	ProLiant ) r_hw_sn=\`dmidecode | grep -A3 -i 'Product Name' | grep Serial | awk '{print \$3}'| tr -d '\n'\`; cur_fw_bank=\`printf \"HP NA\"\` cur_fw=\`dmidecode | grep -i 'Firmware Revision' | awk '{print \$3}'| tr -d '\n'\`; r_hw_type=\`dmidecode | grep 'Product Name' | awk '{print \$3,\$4,\$5}'| tr -d '\n'\`; 
		hdd_size=\`fdisk -l 2>/dev/null | grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; 
		hdd_model=\`smartctl -a -d cciss,0 /dev/cciss/c0d0| grep 'Device:' | awk '{print \$2,\$3}'|tr -d '\n'\`; 
			if [[ -z \$hdd_model ]]; then hdd_model=\`smartctl -a /dev/sda 2>/dev/null| grep 'Device:' | awk '{print \$2 \$3}'|tr -d '\n'\`; fi; 
		hdd_heal=\`smartctl -a -d cciss,0 /dev/cciss/c0d0  2>/dev/null| grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`; 
			if [[ -z \$hdd_heal ]]; then hdd_heal=\`smartctl -a /dev/sda  2>/dev/null| grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`; fi; ;;	
	HPE ) r_hw_sn=\`dmidecode | grep -A4 'System Information' | grep Serial | awk '{print \$3}'| tr -d '\n'\`; cur_fw_bank=\`printf \"HP NA\"\` cur_fw=\`printf \"FW: \"; dmidecode | grep -i 'Firmware Revision' | awk '{print \$3}'| tr -d '\n'; printf \" BIOS: \";dmidecode | grep -i 'BIOS Rev' | awk '{print \$NF}'| tr -d '\n';\`; r_hw_type=\`dmidecode | grep -A4 'System Information' | grep 'Product Name' | awk '{print \$3,\$4,\$5}'| tr -d '\n'\`; 
		hdd_size=\`fdisk -l 2>/dev/null | grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; 
		hdd_model=\`smartctl -a -d cciss,0 /dev/cciss/c0d0| grep 'Device:' | awk '{print \$2,\$3}'|tr -d '\n'\`; 
			if [[ -z \$hdd_model ]]; then hdd_model=\`smartctl -a /dev/sda | grep -E 'Vendor|Product' |awk '{print \$NF}' |tr '\n' ' '|tr -d '\n'\`; fi; 
		hdd_heal=\`smartctl -a -d cciss,0 /dev/cciss/c0d0| grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`; 
			if [[ -z \$hdd_heal ]]; then hdd_heal=\`smartctl -a /dev/sda | grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`; fi; ;;	
	LANGLEY4 ) runuser -l oracle8 '\$ORACLE_HOME/OPatch/opatch' lsinventory 2>/dev/null > /tmp/lnx_hw_au.txt; hdd_size=\`fdisk -l /dev/sda 2>/dev/null | grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; hdd_model=\`smartctl -a /dev/sda | grep 'Device:' | awk '{print \$2 \$3}'|tr -d '\n'\`; hdd_heal=\`smartctl -a /dev/sda | grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`;cur_fw_bank=\`printf \"LANGLEY4 NA\"\` cur_fw=\`dmidecode | grep -m 1 'Version:' | awk '{print \$2}'| tr -d '\n'\`; r_hw_type=\`printf 'INTEL LANGLEY4 '&& dmidecode | grep 'Product Name'| tail -1 | awk '{print \$3}'| tr -d '\n'\`;r_hw_sn=\`dmidecode | grep -A3 -i 'Product Name'| head -3 | grep Serial | awk '{print \$3}'| tr -d '\n'\`;; 
	BALLENGER ) runuser -l oracle8 '\$ORACLE_HOME/OPatch/opatch' lsinventory 2>/dev/null > /tmp/lnx_hw_au.txt; hdd_size=\`fdisk -l /dev/sda 2>/dev/null | grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; hdd_model=\`smartctl -a /dev/sda | grep 'Device:' | awk '{print \$2 \$3}'|tr -d '\n'\`; hdd_heal=\`smartctl -a /dev/sda | grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`;cur_fw_bank=\`printf \"BALLENGER NA\"\` cur_fw=\`dmidecode | grep 'BIOS Revision' | awk '{print \$3}'| tr -d '\n'\`; r_hw_type=\`printf 'INTEL BALLENGER '&&dmidecode | grep -m 1 'Product Name'| awk '{print \$3}'| tr -d '\n'\`;r_hw_sn=\`dmidecode | grep -A3 -i 'Product Name'| head -3 | grep Serial | awk '{print \$3}'| tr -d '\n'\`;; 
	DPM3 ) hdd_size=\`fdisk -l /dev/sda 2>/dev/null | grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; hdd_model=\`smartctl -a /dev/sda | grep 'Device:' | awk '{print \$2 \$3}'|tr -d '\n'\`; hdd_heal=\`smartctl -a /dev/sda | grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`;cur_fw_bank=\`printf \"DPM3 NA\"\` cur_fw=\`dmidecode | grep -m 1 Version | awk '{print \$2}'| tr -d '\n'\`; r_hw_type=\`dmidecode | grep 'Product Name' | awk '{print \$4,\$3}'| tr -d '\n'\`;r_hw_sn=\`printf \"See IPMI FRU\"\`;; 
	DPM2 | DPM1 ) hdd_size=\`fdisk -l /dev/sda 2>/dev/null | grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; hdd_model=\`smartctl -a /dev/sda | grep 'Device:' | awk '{print \$2 \$3}'|tr -d '\n'\`; hdd_heal=\`smartctl -a /dev/sda | grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`;cur_fw_bank=\`printf \"DPM2 NA\"\` cur_fw=\`printf \"DPM2 NA\"\`; r_hw_type=\`printf \"DPM2\"\`;r_hw_sn=\`printf \"DPM2\"\`;; 
	* ) hdd_size=\`fdisk -l 2>/dev/null | grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; hdd_model=\`smartctl -a /dev/sda 2>/dev/null | grep 'Device:' | awk '{print \$2 \$3}'|tr -d '\n'\`; hdd_heal=\`smartctl -a /dev/sda 2>/dev/null | grep 'Health' |awk '{print \$NF}'|tr -d '\n'\`;cur_fw_bank=\`printf \"NA\"\` cur_fw=\`printf \"NA\"\`; r_hw_type=\`printf \"NA\"\`;r_hw_sn=\`printf \"NA\"\`;; esac
score=\`version 2>/dev/null | grep -i lnx_score | awk '{print\$2}'| tr -d '\n'\`
hw_arch=\`version 2>/dev/null | grep -i HW_ARCH | awk '{print\$2}'| tr -d '\n'\`
ram=\`free | grep -i mem | awk '{print\$2}'\`
orac_ver=\`runuser -l oracle 'sqlplus -V 2>/dev/null'| awk '{ print \$3}'|tr -d '\n'\`
orad_ver=\`grep Database /tmp/lnx_hw_au.txt |tail -1 | awk '{print \$NF}'|tr -d '\n'\`
tt_ver=\`grep TimesTen /tmp/lnx_hw_au.txt |tail -1 | awk '{print \$NF}'|tr -d '\n'\`
c_cores=\`egrep -E '^physical|core id' /proc/cpuinfo| xargs -l2 | sort -u | uniq | wc -l| tr -d '\n'\`
c_threads=\`grep -i 'processor' /proc/cpuinfo | sort -u | wc -l| tr -d '\n'\`
core_enabled=\`dmidecode -t processor 2>/dev/null | grep -i 'Core Enabled' | awk '{print \$3}' | tr '\n' '+'| tr -d '\n'| head -c-1 2>/dev/null\`
cpu_m=\`grep -i intel /proc/cpuinfo | grep -vE 'vendor_id|flags' | tail -1  | awk '{print\$7 \$5}'\`
uptime=\`uptime | awk '{print \$3, \$4}'|tr -d ','\`
max_files=\`grep fs.file /etc/sysctl.conf |grep -v '#'| awk -F [=] '{ print \$2}'|tr -d '\n'\`
file_limit=\`ulimit -n|tr -d '\n'\`
our_kernel=\`uname -r|tr -d '\n'\`
java_version=\`java -version 2>&1 |head -n 1| awk '{print \$3}' |tr -d '\"'|tr -d '\n'\`
up_version=\`grep -i wrapper.java.additional.4= /home/jboss/conf/wrapper.conf 2>/dev/null| awk -F '=' '{print \$3}'\`
wl_version=\`source ~/.bash_profile; grep -i Server \$BEA_HOME/registry.xml 2>/dev/null | grep version | awk -F '\"' '{print \$4}'|tr -d '\n'\`
nic_drivers=\`modinfo bnx2 2>/dev/null|grep ^version|awk '{print \$2}'|tr '\n' ' ';modinfo bnx2i 2>/dev/null|grep ^version|awk '{print \$2}'|tr '\n' ' ';modinfo bnx2x 2>/dev/null|grep ^version|awk '{print \$2}'|tr -d '\n'\`
app_version_date=\`rpm -qa --qf '%{VERSION}| %{INSTALLTIME:day}| %{NAME}\n' | grep -E 'CBS|sgu' | grep -vE 'Age|RIP|PERL|DBC|sguconf' | sort | tail -1 | awk -F '|' '{print\$1\" |\"\$2}'| tr -d '\n'\`
case \$hostik in 
	upm1 | upm2 ) hw_arch=\`printf \"i686\"\`; /opt/Navisphere/bin/navicli -h emc1 getagent > /tmp/navi_agent.txt 2>/dev/null; emc=\`grep Model: /tmp/navi_agent.txt | awk '{print \$2}'| tr -d '\n'; printf ' |'; grep No: /tmp/navi_agent.txt | awk '{print \$3}'| tr -d '\n'; printf ' |'; grep Revision: /tmp/navi_agent.txt | awk '{print \$2}'| tr -d '\n';\`;; 
	oam1 ) v7k=\`ssh superuser@nas_console 'lssystem' | grep product_name| awk '{print \$2, \$3, \$4}'| tr -d '\n';printf ' |';ssh superuser@nas_console 'lsenclosure' | grep io_grp| awk '{print \$3, \$7}' | tr '\n' ' ';printf ' |';ssh superuser@nas_console 'lsenclosure' | grep io_grp| awk '{print \$3, \$8}' | tr '\n' ' ';printf ' |';ssh superuser@nas_console 'lssystem' | grep code_level| awk '{print \$2}'| tr -d '\n';printf ' |';ssh superuser@nas_console 'lsdrive' | grep failed| wc -l | tr '\n' ' ';printf ' |';ssh superuser@nas_console 'lssystem' | grep console_IP| awk '{print \$2}'| tr -d '\n'\`;; 
	oam2 ) v7k=\`printf \"same as node1 |same as node1 |same as node1 |same as node1 |same as node1 \"\`;; 
	upmdb* ) hdd_size=\`fdisk -l /dev/sda 2>/dev/null | grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; dd=\`ssh -q sysadmin@dd 'system show modelno' | awk '{print \$3}'| tr -d '\n';printf ' |';ssh -q sysadmin@dd 'system show serialno' | awk '{print \$3}'| tr -d '\n';printf ' |';ssh -q sysadmin@dd 'system show version' | awk '{print \$4}'| tr -d '\n';printf ' |';ssh -q sysadmin@dd 'disk status' | grep oper | awk '{print \$1}'| tr -d '\n';printf ' |';ssh -q sysadmin@dd 'system show uptime' | grep load | awk '{print \$3, \$4}'| tr -d '\n'| tr -d ','\`;; 
	backup-gw1a ) hdd_size=\`fdisk -l /dev/sda 2>/dev/null | grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; v7k=\`ssh superuser@san_console 'lssystem' | grep product_name| awk '{print \$2, \$3, \$4}'| tr -d '\n';printf ' |';ssh superuser@san_console 'lsenclosure' | grep io_grp| awk '{print \$3, \$7}' | tr '\n' ' ';printf ' |';ssh superuser@san_console 'lsenclosure' | grep io_grp| awk '{print \$3, \$8}' | tr '\n' ' ';printf ' |';ssh superuser@san_console 'lssystem' | grep code_level| awk '{print \$2}'| tr -d '\n';printf ' |';ssh superuser@san_console 'lsdrive' | grep failed| wc -l | tr '\n' ' ';printf ' |';ssh superuser@san_console 'lssystem' | grep console_IP| awk '{print \$2}'| tr -d '\n'\`; v5k=\`ssh superuser@san2_console 'lssystem' | grep product_name| awk '{print \$2, \$3, \$4}'| tr -d '\n';printf ' |';ssh superuser@san2_console 'lsenclosure' | grep io_grp| awk '{print \$3, \$7}' | tr '\n' ' ';printf ' |';ssh superuser@san2_console 'lsenclosure' | grep io_grp| awk '{print \$3, \$8}' | tr '\n' ' ';printf ' |';ssh superuser@san2_console 'lssystem' | grep code_level| awk '{print \$2}'| tr -d '\n';printf ' |';ssh superuser@san2_console 'lsdrive' | grep failed| wc -l | tr '\n' ' ';printf ' |';ssh superuser@san2_console 'lssystem' | grep console_IP| awk '{print \$2}'| tr -d '\n'\`;; 
	backup-gw1b ) hdd_size=\`fdisk -l /dev/sda 2>/dev/null | grep GB | awk '{print \$3 \$4}' | tr -d ','|tr -d '\n'\`; v7k=\`printf \"same as node1 |same as node1 |same as node1 |same as node1 |same as node1 \"\`; v5k=\`printf \"same as node1 |same as node1 |same as node1 |same as node1 |same as node1 \"\`;; 
	* ) emc=\`printf \"NA |NA |NA\"\`; v7k=\`printf \"NA |NA |NA |NA |NA\"\`; dd=\`printf \"NA |NA |NA |NA |NA\"\`; v5k=\`printf \"NA |NA |NA |NA |NA\"\`;; esac
if [[ -z \$hw_type ]]; then hw_type=\`printf \"NA\"\`; fi
if [[ -z \$hw_arch ]]; then hw_arch=\`printf \"NA\"\`; fi
if [[ -z \$score ]]; then score=\`printf \"NA\"\`; fi
if [[ -z \$orac_ver ]]; then orac_ver=\`printf \"NA\"\`; fi
if [[ -z \$orad_ver ]]; then orad_ver=\`printf \"NA\"\`; fi
if [[ -z \$hdd_heal ]]; then hdd_heal=\`printf \"NA\"\`; fi
if [[ -z \$java_version ]]; then java_version=\`printf \"NA\"\`; fi
if [[ -z \$up_version ]]; then up_version=\`printf \"NA\"\`; fi
if [[ -z \$wl_version ]]; then wl_version=\`printf \"NA\"\`; fi
if [[ -z \$tt_ver ]]; then tt_ver=\`printf \"NA\"\`; fi
if [[ -z \$core_enabled ]]; then core_enabled=\`printf \"NA\"\`; fi
if [[ -z \$app_version_date ]]; then app_version_date=\`printf \"NA |NA\"\`; fi
if [[ -z \$v5k ]]; then v5k=\`printf \"NA |NA |NA |NA |NA\"\`; fi
if [[ -z \$dd ]]; then dd=\`printf \"NA |NA |NA |NA |NA\"\`; fi
if [[ -z \$v7k ]]; then v7k=\`printf \"NA |NA |NA |NA |NA\"\`; fi
if [[ -z \$emc ]]; then emc=\`printf \"NA |NA |NA\"\`; fi
if [[ -z \$cur_fw_bank ]]; then cur_fw_bank=\`printf \"NA\"\`; fi
if [[ -z \$cur_fw ]]; then cur_fw=\`printf \"NA\"\`; fi
printf \"\$hostik |\$ip_addr |\$routes |\$r_hw_type |\$r_hw_sn |\$score |\$our_kernel |\$hw_arch |\$app_version_date |\$up_version |\$orac_ver |\$orad_ver |\$tt_ver |\$wl_version |\$java_version |\$ram |\$c_cores |\$c_threads |\$core_enabled |\$cpu_m |\$hdd_size |\$hdd_model |\$hdd_heal |\$cur_fw_bank |\$cur_fw |\$max_files |\$file_limit |\$uptime |\$nic_drivers |\$emc |\$v7k |\$v5k |\$dd |\";";printf "\n";done;
#Thats all folks!

#awk -F '|' '{print $2 $12 $13}' *.LINUX_HW_LIST.csv

#mshell secadmin/passw0rd 'version' 2>/dev/null | grep \$hostik | awk '{print \$8}'

#rpm -qa --qf '%{VERSION}| %{INSTALLTIME:day} %{NAME}\n' | grep CBS | sort | tail -1 | awk '{print $1}'| tr -d '\n'

# rpm -qa --qf '(%{INSTALLTIME:day}): %{NAME}-%{VERSION}\n
# rpm -qa --qf '%{NAME} %{VERSION} %{INSTALLTIME}\n' | grep ^CBS
# rpm -qa --qf '%{VERSION} %{NAME}\n' | grep CBS | sort | tail -1   

#runuser -l oracle $ORACLE_HOME/OPatch/opatch lsinventory | awk '/^Oracle/ {print $NF}' | tail -1
#ssh dslu125 "runuser -l oracle '\$ORACLE_HOME/OPatch/opatch lsinventory' | grep -A2 Installed| tail -1 | awk '{print \$3}'"
# lsnode -v
#admin@NAS_VIP[NAS_VIP]$ lsnode -v
#Hostname     IP          Description             Role                         Product version Connection status GPFS status CTDB status Username Is manager Is quorum Daemon ip address Daemon version Is Cache Recovery master Monitoring enabled Ctdb ip address OS name         OS family Serial number Last updated
#mgmt001st001 169.254.8.2 active management node  management,interface,storage 1.5.1.2-1       OK                active      active      root     yes        yes       169.254.8.2       1350           no       yes             yes                169.254.8.2     RHEL 6.4 x86_64 Linux     7810092       1/29/18 7:59 PM
#mgmt002st001 169.254.8.3 passive management node management,interface,storage 1.5.1.2-1       OK                active      active      root     yes        yes       169.254.8.3       1350           no       no              yes                169.254.8.3     RHEL 6.4 x86_64 Linux     7810110       1/29/18 7:59 PM
#admin@NAS_VIP[NAS_VIP]$

#dmidecode_cores=dmidecode -t processor | grep -i 'Core Count' | awk '{print $3}' | tr -d '\n'
#dmidecode_threads=dmidecode -t processor | grep -i 'Thread Count' | awk '{print $3}' | tr -d '\n'
#core_enabled=dmidecode -t processor | grep -i 'Core Enabled' | awk '{print $3}' | tr -d '\n'


#DD
# alerts show current
