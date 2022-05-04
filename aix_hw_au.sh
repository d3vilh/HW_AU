#!/bin/bash
#  ∆  Philipp Shilov 2016 First task for support 
# ∆ ∆ Pavel Dokuchaev 2019 added Cisco MDS FW level 
#v.0.1.5 + ROOTVG HDD SIZE #v.0.1.4 Fedonov request #v.0.1.3 inventory file introduced #v.0.1.2 + UAC exp date #v.0.1.1 new GIT versioning #v.0.6.4 more CPU details + up_version enfastment # v.0.6.3.1 Small fix. #v.0.6.3 02.04.2021 Templates introduced # v.0.6.2.2 small fix. #v.0.6.2.1 Java and UP VER added #v.0.6.1 DBCORE VER added #v.0.6.0 P9 support added. #v.0.5.3 Added FW level Cisco MDS #v.0.5.2 30.08.2019 mass "Unknown format" fix. #v.0.5.1 21.08.2019 nsradmin and v7k get bugs fixed for NGSCORE 7.x, Oracle version added. # v0.1 15.11.2015, v.0.2 14.03.2018 NSR license ext date added, v.0.3 27.07.2018 WA for stderr and for flash storage3, v.0.4 21.03.2019 NXOS FCSW & Networker version added
if [ ! -n "$1" ]; then 
	printf "\n Runs Hardware Inventory checks against any AIX-based servers.\n  Usage: ./aix_hw_au.sh HOSTNAME SITE_ID\n   Where:\n     HOSTNAME can be necessary server to run inventory on or mask for the group of hosts from the /etc/hosts\n     SITE_ID is optional parameter, will be inserted as first column of output. PROD_SITE is used by default\n  Examples:\n    ./aix_hw_au.sh sdp1b MSK\n    ./aix_hw_au.sh sdp EKT\n    ./aix_hw_au.sh sdp23\n\n";
	exit; 
fi;
host_match=$1;  # Hostname to run audit

aix_ex_tmplt="MY_TEMPLATE";  # Template to exclude hosts from the /etc/hosts of your master node. i.e. grep -viE "template" /etc/hosts; its aix_ex_tmplt="MY_TEMPLATE" by default.
if [ "$aix_ex_tmplt" = "MY_TEMPLATE" ]; then 
	aix_ex_tmplt="^ *#|audit_exclude|localhost|farm|blu|acmi|asmi|emc|v7000|om|hmc|fcs|emc|tape|zbx|hsbu|mau|rctu"; 
fi

site_id=$2; # SITE_ID for first column
if [ ! -n "$2" ]; then 
	site_id=PROD_SITE; 
fi

#File with hosts inventory. Can be /etc/hosts or similar, but sorted, wo duplicated entries.
inventory_file=inventory.$site_id 

printf "SITE|HOSTNAME|HW TYPE|SYSTEM MODEL|SERIAL|NGSCORE|DBCORE|ORACLE DB|ORACLE CLI|UP VERSION|JAVA VERSION|FIRMWARE|UAK EXP DATE|AIX OS LEVEL|BLU MODEL|BLU SERIAL|NSR LICENSE EXP|NETWORKER VERSION|FCSWA MODEL|FCSWA SN|FCSWA FW LEVEL|FCSWB MODEL|FCSWA SN|FCSWB FW LEVEL|EMC MODEL|EMC SERIAL|EMC FLARE|V7k MODEL|V7k TYPE|V7k ENCLOSURE SN|v7K FW|V7k failed HDDs|V7k CONSOLE|V7k2F MODEL|V7k2F TYPE|V7k2F ENCLOSURE SN|v7K2F FW|V7k2F failed SSDs|V7k2F CONSOLE|CLUST IP|NODE IP|HMC IP|LPAR INFO|AUTO RESTART|CPU CLOCK|NUM OF PHY CPU|CPU SMT MODE|NUM OF LOG CPU|RAM SIZE|GOOD RAM SIZE|NUM OF RAM MODULES|SIZE OF RAM MODULES(MB)|ROOTVG SIZE GB|PAGE SIZE|COUNT ERRPT|UNIQ ERRPT|UPTIME\n";

# GENERAL LOOP
for host in $(grep -iE $host_match $inventory_file|grep -viE "$aix_ex_tmplt"|awk {'print$2'}|sort|uniq | grep -E 'a|b');
	do ping -c1 -W1 $host 1>/dev/null && printf "$site_id|$host|" && ssh -q $host "
	hostmane=\`hostname\`
	hostmane_ip=\$hostmane\`printf '_'\`
	find /tmp -name 'prtconf.txt' -mtime +120 -exec rm {} \;
	find /tmp -name 'aix_hw_au.txt' -mtime +120 -exec rm {} \;
	find /tmp -name 'navi_agent.txt' -mtime +120 -exec rm {} \;
	if [ ! -f /tmp/prtconf.txt ]; then prtconf > /tmp/prtconf.txt 2>/dev/null ; fi
	if [ ! -f /tmp/aix_hw_au.txt ]; then su - oracle8 -c '\$ORACLE_HOME/OPatch/opatch' lsinventory 2>/dev/null > /tmp/aix_hw_au.txt; fi
	if [ ! -f /tmp/navi_agent.txt ]; then naviseccli -user root -password comverse -scope 0 -h emc1 getagent > /tmp/navi_agent.txt 2>/dev/null; fi
	admin_clust_alias=\`su - -c cllsnw | grep ADMIN_CONNECT | awk '{print \$8}'\`
	clust_ip=\`su - -c cllsnode -i \$hostmane  2>/dev/null | grep \$admin_clust_alias | awk '{print \$9}';\`
	ip_addr=\`su - -c cldump|grep \$hostmane_ip|grep admin|awk '{print \$2}'|tr -d '\n';\`
	sys_model=\`uname -M\`
	hw_type=\`grep 'Processor Type:' /tmp/prtconf.txt| awk '{print \$3}'| tail -c 7 |tr -d '\n';\`
	serial=\`grep 'Machine Serial Number' /tmp/prtconf.txt | awk '{print \$4}'\`
	blu=\`lscfg -vl rmt0 2>/dev/null | grep -i 'Manufacturer' | awk -F '[.]' '{print \$17}' | tr -d '\n [:blank:]'; lscfg -vl rmt0 2>/dev/null | grep -i 'Machine' | awk -F '[.]' '{print \$7}' | tr -d '\n [:blank:]';\`
	blu_sn=\`lscfg -vl rmt0 2>/dev/null | grep -i 'Serial' | awk -F '[.]' '{print \$16}' | tr -d '\n [:blank:]';\`
	nsr_license=\`printf 'print type:nsr license\\n\\n' 2> /dev/null | nsradmin -s sdp_nsr -i - 2>/dev/null | grep expiration | grep -v Authorized | awk '{print \$3,\$4,\$5}'| tr -d '\n';\`
	nsr_version=\`print 'show name ; Networker version\nprint type:NSR client;\n' 2> /dev/null|/usr/bin/nsradmin -s sdp_nsr -i - 2> /dev/null|grep 'NetWorker version:'|grep Build|head -1 | awk '{print \$3}'| tr -d '\n';\`
	emc=\`grep Model: /tmp/navi_agent.txt | awk '{print \$2}'| tr -d '\n'; printf '|'; grep No: /tmp/navi_agent.txt | awk '{print \$3}'| tr -d '\n'; printf '|'; grep Revision: /tmp/navi_agent.txt | awk '{print \$2}'| tr -d '\n';\`
	errpt=\`errpt | wc -l| tr -d '\n [:blank:]';\`
	java_version=\`java -version 2>&1 |head -n 1| awk '{print \$3}' |tr -d '\"'|tr -d '\n'\`
	up_version=\`grep -i wrapper.java.additional.5= \$JBOSS_HOME/conf/wrapper.conf 2>/dev/null| awk -F '=' '{print \$3}'\`;
	uniq_errpt=\`errpt | awk '{print \$1}' | sort | uniq | grep -v IDENT | wc -l| tr -d '\n [:blank:]';\`
	hmc_ip=\`lsrsrc IBM.ManagementServer 2>/dev/null|grep Hostname | grep -v Local | awk -F '[\"]' '{print \$2}'| tr '\n' ' ';\`
	fcswa_model=\`ssh -q -o BatchMode=yes audit@fcswa 'show hardware | include Chassis' 2> /dev/null | head -1 | awk '{print \$1,\$2,\$3}' |tr -d '\n';\`
	fcswa_sn=\`ssh -q -o BatchMode=yes audit@fcswa 'sh inventory' 2> /dev/null | head -2 |tail -1 | awk '{print \$8}' |tr -d '\" \n';\`
	fcswa_fw=\`ssh -q -o BatchMode=yes audit@fcswa 'sh ver | include system\:' | awk '{print \$3}' |tr -d '\n';\`
	fcswb_model=\`ssh -q -o BatchMode=yes audit@fcswb 'show hardware | include Chassis' 2> /dev/null | head -1 | awk '{print \$1,\$2,\$3}' |tr -d '\n';\`
	fcswb_sn=\`ssh -q -o BatchMode=yes audit@fcswb 'sh inventory' 2> /dev/null | head -2 |tail -1 | awk '{print \$8}' |tr -d '\" \n';\`
	fcswb_fw=\`ssh -q -o BatchMode=yes audit@fcswb 'sh ver | include system\:' | awk '{print \$3}' |tr -d '\n';\`
	uptm=\`uptime | awk '{print \$3,\$4}'| tr -d '\n ,';\`
	lpar=\`grep 'LPAR Info' /tmp/prtconf.txt | awk '{print \$3,\$4}'| tr -d '\n';\`
	fw=\`lsmcode -A | grep ^sys0 | tr -d '\n';\`
	uac_date=\`lscfg -vpl sysplanar0 | grep -E 'Microcode Entitlement|Access Key Exp' |awk -F '[.]' '{print \$3}'|tr -d '\n';\`
	autorest=\`grep 'Auto Restart:' /tmp/prtconf.txt | awk '{print \$3}'| tr -d '\n'; \`
	ram_size=\`grep 'Memory Size:' /tmp/prtconf.txt | grep -v Good| awk '{print \$3,\$4}'| tr -d '\n';\`
	good_ram_size=\`grep 'Good Memory Size:' /tmp/prtconf.txt | awk '{print \$4,\$5}'| tr -d '\n'; \`
	num_of_ram_modules=\`lscfg -vp | grep -e Size | awk '{print substr (\$1,29)}'  | wc -l | bc\`
	size_of_ram_modules=\`lscfg -vp | grep -e Size | awk '{print substr (\$1,29)}'| tr '\n' ','|sed 's/.\$//'\`
	page_size=\`svmon -G | grep KB | awk '{print \$1, \$2, \$3}' | tr -d '\n'\`
	num_of_cpu=\`grep Processors /tmp/prtconf.txt | awk '{print \$4}'\`
	cpu_speed=\`grep 'Processor Clock Speed:' /tmp/prtconf.txt | awk '{print \$4,\$5}'| tr -d '\n'; \`
	cpu_smt_mode=\`smtctl | grep supports | awk '{print \$6}'| tr -d '\n'; \`
	num_cpu_cores=\`mpstat | grep configuration | awk -F '[=]' '{print \$2}' | awk '{print \$1}'| tr -d '\n'; \`
	rootvg_size=\`getconf DISK_SIZE /dev/hdisk0| awk '{ a = \$1; rkb = a / 1000; print rkb}' OFMT='%1.0f' | tr -d '\n';\`
	os_level=\`oslevel -s 2>/dev/null | tr -d '\n';\`
	dbcore_ver=\`rpm -qa | grep DBC_TKS | awk -F '-' '{print \$2}' |tr -d '\n';\`
	orac_ver=\`grep Client /tmp/aix_hw_au.txt |tail -1 | awk '{print \$NF}'| tr -d '\n';\`
	orad_ver=\`grep Database /tmp/aix_hw_au.txt | grep 'Patch description' |tail -1 | awk '{print \$(NF-1)}'| tr -d '\n';\`
	if [[ -z \$orad_ver ]]; then orad_ver=\`grep Database /tmp/aix_hw_au.txt | grep 'Patch Set' |tail -1 | awk '{print \$(NF)}'| tr -d '\n';\`; fi
	if [[ -z \$orad_ver ]]; then orad_ver=\`grep Database /tmp/aix_hw_au.txt | awk '{print \$(NF)}'| tr -d '\n';\`; fi
	ngscore=\`cat /etc/BaseOS_version | grep 'SDP NGSCORE' | awk '{print \$4}' | sort | tail -1| tr -d '\n';\`
	if [[ \$(hostname -s) = sdp1 ]] && [[ \$hw_type = POWER8 ]]; then
		v7000_model=\`ssh superuser@san_console 'lssystem' 2> /dev/null | grep product_name| awk '{print \$2, \$3, \$4}'| tr -d '\n'|grep -v san_console;\`
		v7000_enclosure_type=\`ssh superuser@san_console 'lsenclosure' 2> /dev/null | grep io_grp| awk '{print \$3\":\"\$7}'| tr '\n' ' '|tr -d '\" \n'\`
		v7000_sn=\`ssh superuser@san_console 'lsenclosure' 2> /dev/null | grep io_grp| awk '{print \$3\":\"\$8}'| tr '\n' ' '|tr -d '\" \n'\`
		v7000_fw=\`ssh superuser@san_console 'lssystem' 2> /dev/null | grep code_level| awk '{print \$2}'| tr -d '\n';\`
		v7000_ip=\`ssh superuser@san_console 'lssystem' 2> /dev/null | grep console_IP| awk '{print \$2}'| tr -d '\n'; \`
		v7000_fhdd=\`ssh superuser@san_console 'lsdrive' 2> /dev/null | grep failed| wc -l | tr -d ' '\`
		v7000f_model=\`printf \"NA\"\`
		v7000f_enclosure_type=\`printf \"NA\"\`
		v7000f_fw=\`printf \"NA\"\`
		v7000f_ip=\`printf \"NA\"\`
		v7000f_sn=\`printf \"NA\"\`
		v7000f_fhdd=\`printf \"NA\"\`
		if [[ \$(oslevel -s 2> /dev/null| head -c4) = 7200 ]]; then
			v7000f_model=\`ssh superuser@san_console_flash 'lssystem' 2> /dev/null | grep product_name| awk '{print \$2, \$3, \$4}'| tr -d '\n';\`
			v7000f_enclosure_type=\`ssh superuser@san_console_flash 'lsenclosure' 2> /dev/null | grep -v status | awk '{print \$3, \$4}'  | tr '\n' ' '|tr -d '\" \n'\`
			v7000f_fw=\`ssh superuser@san_console_flash 'lssystem' 2> /dev/null | grep code_level| awk '{print \$2}'| tr -d '\n';\`
			v7000f_ip=\`ssh superuser@san_console_flash 'lssystem' 2> /dev/null | grep console_IP| awk '{print \$2}'| tr -d '\n';\`
			v7000f_sn=\`ssh superuser@san_console_flash 'lsenclosure' 2> /dev/null | grep -v status| awk '{print \$5}' | tr '\n' ' '|tr -d '\" \n'\`
			v7000f_fhdd=\`ssh superuser@san_console_flash 'lsdrive' 2> /dev/null | grep failed| wc -l | tr '\n' ' ' |tr -d ' '\`
				if [[ -z \$v7000_model ]]; then v7000_model=\`printf \"NA\"\`; fi
				if [[ -z \$v7000_enclosure_type ]]; then v7000_enclosure_type=\`printf \"NA\"\`; fi
				if [[ -z \$v7000_fw ]]; then v7000_fw=\`printf \"NA\"\`; fi
				if [[ -z \$v7000_ip ]]; then v7000_ip=\`printf \"NA\"\`; fi
				if [[ -z \$v7000_sn ]]; then v7000_sn=\`printf \"NA\"\`; fi
				if [[ -z \$v7000_fhdd ]]; then v7000_fhdd=\`printf \"NA\"\`; fi
			nsr_version=\`printf \"NA\"\`
			java_version=\`/usr/java6/bin/java -version 2>&1 |head -n 1| awk '{print \$3}' |tr -d '\"'|tr -d '\n'\`
		fi
		emc=\`printf \"NA|NA|NA\"\`
	else
		v7000_model=\`printf \"NA\"\`
		v7000_enclosure_type=\`printf \"NA\"\`
		v7000_fw=\`printf \"NA\"\`
		v7000_ip=\`printf \"NA\"\`
		v7000_sn=\`printf \"NA\"\`
		v7000_fhdd=\`printf \"NA\"\`
		v7000f_model=\`printf \"NA\"\`
		v7000f_enclosure_type=\`printf \"NA\"\`
		v7000f_fw=\`printf \"NA\"\`
		v7000f_ip=\`printf \"NA\"\`
		v7000f_sn=\`printf \"NA\"\`
		v7000f_fhdd=\`printf \"NA\"\`
	fi
	if [[ \$(hostname -s) = sdp1 ]] && [[ \$hw_type = POWER9 ]]; then
		v7000f_model=\`ssh superuser@san_console_flash 'lssystem' 2> /dev/null | grep product_name| awk '{print \$2, \$3, \$4}'| tr -d '\n';\`
		v7000f_enclosure_type=\`ssh superuser@san_console_flash 'lsenclosure' 2> /dev/null | grep -v status | awk '{print \$3, \$4}'  | tr '\n' ' '| tr -d '\" \n'\`
		v7000f_fw=\`ssh superuser@san_console_flash 'lssystem' 2> /dev/null | grep code_level| awk '{print \$2}'| tr -d '\n';\`
		v7000f_ip=\`ssh superuser@san_console_flash 'lssystem' 2> /dev/null | grep console_IP| awk '{print \$2}'| tr -d '\n';\`
		v7000f_sn=\`ssh superuser@san_console_flash 'lsenclosure' 2> /dev/null | grep -v status| awk '{print \$5}' | tr '\n' ' '\`
		v7000f_fhdd=\`ssh superuser@san_console_flash 'lsdrive' 2> /dev/null | grep failed| wc -l | tr '\n' ' '|tr -d ' '\`
		emc=\`printf \"NA|NA|NA\"\`
		java_version=\`/usr/java6/bin/java -version 2>&1 |head -n 1| awk '{print \$3}' |tr -d '\"'|tr -d '\n'\`
	fi
	if [[ \$(hostname -s) = sdp2 ]] && [[ \$hw_type = POWER8 || \$hw_type = POWER9 ]]; then
		emc=\`printf \"NA|NA|NA\"\`
		v7000_model=\`printf \"same as on node A\"\`
		v7000_enclosure_type=\`printf \"same as on node A\"\`
		v7000_fw=\`printf \"same as on node A\"\`
		v7000_ip=\`printf \"same as on node A\"\`
		v7000_sn=\`printf \"same as on node A\"\`
		v7000_fhdd=\`printf \"same as on node A\"\`
		v7000f_model=\`printf \"same as on node A\"\`
		v7000f_enclosure_type=\`printf \"same as on node A\"\`
		v7000f_fw=\`printf \"same as on node A\"\`
		v7000f_ip=\`printf \"same as on node A\"\`
		v7000f_sn=\`printf \"same as on node A\"\`
		v7000f_fhdd=\`printf \"same as on node A\"\`
		java_version=\`/usr/java6/bin/java -version 2>&1 |head -n 1| awk '{print \$3}' |tr -d '\"'|tr -d '\n'\`
	fi
	if [[ \$(hostname -s) = sdp2 ]]; then
		fcswa_model=\`printf \"same as on node A\"\`
		fcswa_sn=\`printf \"same as on node A\"\`
		fcswb_model=\`printf \"same as on node A\"\`
		fcswb_sn=\`printf \"same as on node A\"\`
		fcswa_fw=\`printf \"same as on node A\"\`
		fcswb_fw=\`printf \"same as on node A\"\`
	fi
	if [[ -z \$hmc_ip ]]; then hmc_ip=\`printf \"NA\"\`; fi
	if [[ -z \$blu_sn ]]; then blu_sn=\`printf \"NA\"\`; fi
	if [[ -z \$nsr_license ]]; then nsr_license=\`printf \"No Exp Date\"\`; fi
	if [[ -z \$nsr_version ]]; then nsr_version=\`printf \"NA\"\`; fi
	if [[ -z \$orad_ver ]]; then orad_ver=\`printf \"Oh crap\"\`; fi
	if [[ -z \$java_version ]]; then java_version=\`printf \"Not installed\"\`; fi
	if [[ -z \$up_version ]]; then up_version=\`printf \"Not installed\"\`; fi
	if [[ -z \$dbcore_ver ]]; then dbcore_ver=\`printf \"Not there\"\`; fi  
	if [[ -z \$orac_ver ]]; then orac_ver=\`printf \"Not installed\"\`; fi
	if [[ -z \$fcswa_model ]]; then fcswa_model=\`printf \"NA\"\`; fi
	if [[ -z \$fcswa_sn ]]; then fcswa_sn=\`printf \"NA\"\`; fi
	if [[ -z \$fcswa_fw ]]; then fcswa_fw=\`printf \"NA\"\`; fi
	if [[ -z \$fcswb_model ]]; then fcswb_model=\`printf \"NA\"\`; fi
	if [[ -z \$fcswb_sn ]]; then fcswb_sn=\`printf \"NA\"\`; fi
	if [[ -z \$fcswb_fw ]]; then fcswb_fw=\`printf \"NA\"\`; fi
	if [[ -z \$uac_date ]]; then uac_date=\`printf \"NA\"\`; fi
	printf \"\$hw_type|\$sys_model|\$serial|\$ngscore|\$dbcore_ver|\$orad_ver|\$orac_ver|\$up_version|\$java_version|\$fw|\$uac_date|\$os_level|\$blu|\$blu_sn|\$nsr_license|\$nsr_version|\$fcswa_model|\$fcswa_sn|\$fcswa_fw|\$fcswb_model|\$fcswb_sn|\$fcswb_fw|\$emc|\$v7000_model|\$v7000_enclosure_type|\$v7000_sn|\$v7000_fw|\$v7000_fhdd|\$v7000_ip|\$v7000f_model|\$v7000f_enclosure_type|\$v7000f_sn|\$v7000f_fw|\$v7000f_fhdd|\$v7000f_ip|\$clust_ip|\$ip_addr|\$hmc_ip|\$lpar|\$autorest|\$cpu_speed|\$num_of_cpu|\$cpu_smt_mode|\$num_cpu_cores|\$ram_size|\$good_ram_size|\$num_of_ram_modules|\$size_of_ram_modules|\$rootvg_size|\$page_size|\$errpt|\$uniq_errpt|\$uptm\";";
	printf "\n";
done;
#thats all folks!