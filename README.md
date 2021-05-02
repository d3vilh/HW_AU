Hardware Audit tool for Comverse One systems.
=============================================
Runs audit for all AIX and Linux servers in /etc/hosts of your master node and provides CSV file with all the details as result. 

MAIN FEATURES
--------------
Fast and easy to setup.

Require minimal system resources.

Does not require 3rd party software to run.

VM and BM compatible.

The Inventory utility provides following information:

* Server hardware parts report (CPU, RAM, HDD, PCI boards)
* Server Serial Numbers report (Server MB, Storage, Fiber Switches, Tape Libs)
* Server Firmware versions (BIOS, UEFI, NIC, POWER servers)
* OS information (Score version, architecture type, Linux kernel, AIX OS Level)
* HDD and SSD Smart status (HDD & SSD health)
* Linux drivers versions for critical components (NIC modules)
* Server uptime, Limits, MEM Pages and TZ settings
* Running C1 and 3rd party applications version (CBS apps, UPA, Oracle, Java, WebLogic) Advanced Storage report (for EMC CX, DATA Domain, IBM v7000 and IBM fs900) Advanced FCS report (CISCO Nexus)
* Core Network switches inventory (Juniper and Cisco switches)
* Servers Network configuration snapshot (AIX and Linux. MAC, IP, Routing, VIP)

PREREQUISITES
--------------
* Require **Bash version 3** or higher on the master server (`bash --version`) 
* The `/etc/hosts` file on the master server should be reviewed before the first run
* SSH password-less access needs be configured across all UNIX servers (Linux and AIX). If this configuration is missed the utility will ask for the password for every server where no ssh certificates is present
* For IBM v7000 and fs900 storages, ssh password-less access needs to be present on SDP_A node to both storage enclosures(active and stby.). This is default configuration.
* The Hardware Inventory tool support any Linux or AIX versions on the remote servers by default. However, Site specific configuration should be done for `audit.run` script.

PREPARATION
-----------
**1. The `/etc/hosts` file** on the master server should be ready to run inventory, as it takes servers list from the masters server `/etc/hosts` file.
The scripts uses special filters to avoid running inventory on the same host several times. As addition cause you can add special filter to exclude not necessary servers from the inventory list by adding the line `#audit_exclude` for every `/etc/hosts` server record. For example:

``` shell
FARTS:oam1a:/root# grep audit_exclude /etc/hosts 
10.1.1.112 upmdb upmdb_vip #audit_exclude
10.1.1.112 EM_REPOSITORY orac-upmdb upmdb #audit_exclude
```
**FOR BASIC INVENTORY** - skip preparation for IBM Storages and CISCO FCSs

**2. For IBM v7000** add san_console information into the SDP `/etc/hosts` (both nodes):
``` shell
FARTS-SDP1a:sdp1:/# grep -i san /etc/hosts 
10.1.1.125 san_console
10.1.1.138 v7000-1a san1 
10.1.1.139 v7000-1b san2
```
The san_console is an IBM storage enclosures VIP interface. Which can be obtained from the storage active enclosure node (password-less access setup for SDP_A only):
``` shell
FARTS-SDP1a:sdp1:/# ssh superuser@san_console lssystem | grep console 
console_IP 10.1.1.125:443
FARTS-SDP1a:sdp1:/#
```

**3. For IBM fs900** add san_console_flash information into the SDP `/etc/hosts` (both nodes):
``` shell
FARTS-SDP23:sdp1:/# grep -i san_console /etc/hosts 
10.1.1.39 san_storage-23 san1 san_console 
10.1.1.45 san_flash-23 san2 san_console_flash 
FARTS-SDP23:sdp1:/#
```
The san_console_flash is an IBM flash storage enclosures VIP interface. This information can be obtained from the storage active node enclosure (console password-less access setup for SDP_A only by default):
``` shell
FARTS-SDP23:sdp1:/# ssh superuser@san_console_flash lssystem | grep console 
console_IP 10.1.1.45:443
FARTS-SDP23:sdp1:/#
```

**4. Beware that to some POWER8 SDPs both type of the storages** (v7000 and fs900) can be connected to one SDP server (different VGs are located on different storages). Be sure that you have both `san_console` and `san_console_flash` IP addresses in `/etc/hosts` file on **both SDP_A and SDP_B nodes** for this type of servers.

**5. Double check** that SDP_A `known_hosts` file contains records for new san_console and `san_console_flash` hosts:
``` shell
FARTS-SDP23a:sdp1:/# ssh superuser@san_console 'lssystem'| grep code_level 
code_level 7.8.1.10 (build 135.9.1905291321000)
FARTS-SDP23a:sdp1:/# ssh superuser@san_console_flash 'lssystem'| grep code_level 
code_level 7.8.1.10 (build 135.9.1905291321000)
FARTS-SDP23a:sdp1:/#
```

**6. For CISCO FCS** (Nexus modules only) create special inventory user and configure password-less access for SDP_A node on fcswa and fcswb FCSs:
``` shell
FARTS-SDP23:sdp1:/# grep -i fcsw /etc/hosts 
10.1.1.57 fc-sw23a fcswa fcs23a 
10.1.1.58 fc-sw23b fcswb fcs23b
FARTS-SDP23:sdp1:/#
```
Login from SDP_A node to fcswa as admin user and list all connected users to define correct SDP_A IP address:
``` shell
FARTS-FCS-23A# show users
NAME LINE TIME IDLE PID COMMENT
audit pts/0 Jan 21 20:37 . 6669 (10.1.1.56) session=ssh * FARTS-FCS-23A#
```
Copy SDP_A RSA certificate to fcswa node (use IP defined on previous step):
``` shell
FARTS-FCS-23A# copy sftp://root@10.1.1.56/.ssh/id_rsa.pub id_rsa.pub 
```
Confirm certificate now exists on CISCO bootflash device:
``` shell
FARTS-FCS-23A# dir ...
             391    Mar 20 17:27:44 2019  id_rsa.pub
      ...
FARTS-FCS-23A#
```
Create new audit user with reduced access permissions and stick RSA certificate to it:
``` shell
FARTS-FCS-23A# conf t
FARTS-FCS-23A(config)# username audit password Blah-Blah-Blah role network-operator
FARTS-FCS-23A(config)# username audit sshkey file bootflash:id_rsa.pub 
FARTS-FCS-23A(config)# end
FARTS-FCS-23A#
```
Confirm new user has been created with reduced permissions role and RSA certificate:
``` shell
FARTS-FCS-23A# show user-account audit 
        user:audit
        this user account has no expiry date
        roles:network-operator
        ssh public key: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCxFUEqKCuvQiSE0
        ogU2oNplgN9caBmOUOQ556zD4PLzGS5SzBlah-Blah-Blah...
FARTS-FCS-23A#
```
Save new CISCO configuration:
``` shell
FARTS-FCS-23A# copy run start
# [########################################] 100% # Copy complete.
FARTS-FCS-23A# exit
```
**Perform the same steps for SDP_A but from `fcswb (the second)` switch.**

Confirm password-less access is configured for both fcswa and fcswb switches from SDP_A node:
``` shell
FARTS-sdp23a:/# ssh -q audit@fcswa 'sh inventory' | head -1 | awk '{print $4,$5}'; 
MDS 9148S
FARTS-sdp23a:/# ssh -q audit@fcswb 'sh inventory' | head -1 | awk '{print $4,$5}'; 
MDS 9148S
sdp23a:/#
```

FULL SITE INVENTORY
-------------------
To run hardware inventory across all the onsite servers you have to execute `audit.run` script
as superuser with short site name:
``` shell
FARTS-UPM1a:upm1:# ./audit.run FARTS
Keep an eye on the progress. Human input might be required.
   Running HW Inventory on following units:
   SGU, DGU, SLU, DSLU, CRMOMAPP, ... CMVOEM, UPM, UPMDB, OAMAPP, SDP, CPM, WPDB, BF, ADMIN
   PROGRESS: 70%  [################################..............] RUNNING ON: UPM&DB
```
For help information - fire `audit.run` without any keys: 
``` shell
FARTS-UPM1a:upm1:# ./audit.run
   Runs Hardware Inventory checks across all onsite units.
Usage: ./audit.run SITE_ID
Where SITE_ID is short site name. AIX and LINUX inventory scripts will be updated
  with this short name on first audit.run execution.
    Examples:
      ./audit.run FARTS
      ./audit.run FARTS_PROD
      ./audit.run FARTS_TEST
    Prerequisites:
      aix_hw_au.sh - runs Hardware Inventory checks against any AIX-based servers.
      linux_hw_au.sh - runs Hardware Inventory checks against any Linux-based servers.
Be aware that SANbox and EMCds FCSs checks is deprecated in this version, as obsolete HW 
FARTS-UPM1a:upm1:#
```
As a result of this execution you’ll have two .CSV files. First with Linux based servers inventory, second with AIX based servers inventory information:
``` shell
FARTS-UPM1a:upm1:# ls -rlt
-rwxrwxrwx 1 root root 5319 Jan 21 19:40 audit.run
-rwxrwxrwx 1 root root 15880 Jan 21 21:32 linux_hw_au.sh 
-rwxrwxrwx 1 root root 12436 Jan 21 21:32 aix_hw_au.sh
-rw-r--r-- 1 root root 87596 Jan 21 21:43 FARTS.LINUX_HW_LIST.csv 
-rw-r--r-- 1 root root 20161 Jan 21 21:47 FARTS.AIX_HW_LIST.csv 
FARTS-UPM1a:upm1:#
```
Both CSV files will contain all the inventory data with pipe (`|`) symbol used as the columns delimiter:
``` shell
FARTS-UPM1a:upm1:# head -2 YAR.LINUX_HW_LIST.csv
SITE |HOSTNAME |IP ADDR |ROUTE |HW TYPE |HW SN |LNX SCORE |KERNEL |HW ARCH |APP VERSION |APP INSTALL DATE(M/D/Y) |UP VERSION |ORA CLI |ORA DB |TT DB |WL VERSION |JAVA VER |RAM |CORES |THREADS |ENA CORES |CPU |HDD SIZE |HDD MODEL |HDD HEALTH |ACTIVE UEFI BANK |UEFI/BIOS VERSION |FILE-MAX (sysctl.conf) |FILE-LIMIT (ulimit -n)|UPTIME |NIC DRVs |EMC MODEL |EMC SERIAL |EMC FLARE |V7k MODEL |V7k TYPE |V7k ENCLOSURE SN |v7K FW |V7k failed HDDs |V7k CONSOLE |DD MODEL |DD SERIAL |DD OS |DD DISK STATUS |DD UPTIME 
YAR |sgu1a |10.1.1.100 |10.1.1.1 |ProLiant BL460c Gen8 |OLOLO |6.2.1 | 2.6.32-220.el6.i686 |i686 |7.0.5 | Mon Apr 10 2017 |4.120.0 |11.2.0.3.0 |NA |NA |NA | 1.6.0_31 |3983136 |6 |12 |6 |E5-2620Xeon(R) |300.0GB |HP LOGICAL VOLUME |OK |HP NA | 1.51 | 20000 |8192 |327 days |2.1.11 2.7.0.3 1.70.00-0 |NA |NA |NA |NA |NA |NA |NA |NA |NA |NA |NA |NA |NA |
FARTS-UPM1a:upm1:#
```

LINUX HOSTS INVENTORY
---------------------
To run Hardware Inventory checks against any Linux-based servers you have to execute `linux_hw_au.sh` script.
For help information, run `linux_hw_au.sh` without any keys:
``` shell
FARTS-UPM1a:upm1:# ./linux_hw_au.sh
   Runs Hardware Inventory checks against any Linux-based servers.
Usage: ./linux_hw_au.sh HOSTNAME SITE_ID Where:
      HOSTNAME is server to run inventory on or mask for the group of hosts from the /etc/hosts
      SITE_ID is optional parameter, will be inserted as first column of output. PROD_SITE is used
      by default
     Examples:
      ./linux_hw_au.sh sgu21b FARTS
      ./linux_hw_au.sh slu FARTS_PROD
      ./linux_hw_au.sh sgu23
FARTS-UPM1a:upm1:#
```
Once you read all the help, you can execute `linux_hw_au.sh` script as superuser.
Beware the script will not save any data to .CSV files, it will send all the output, about every server to console:
``` shell
FARTS-UPM1a:upm1:# ./linux_hw_au.sh sgu3 FARTS
  SITE |HOSTNAME |IP ADDR |ROUTE |HW TYPE |HW SN |LNX SCORE |KERNEL |HW ARCH |APP VERSION |APP INSTALL DATE(M/D/Y) |UP VERSION |ORA CLI |ORA DB |TT DB |WL VERSION |JAVA VER |RAM |CORES |THREADS |ENA CORES |CPU |HDD SIZE |HDD MODEL |HDD HEALTH |ACTIVE UEFI BANK |UEFI/BIOS VERSION |FILE-MAX (sysctl.conf) |FILE-LIMIT (ulimit -n)|UPTIME |NIC DRVs |EMC MODEL |EMC SERIAL |EMC FLARE |V7k MODEL |V7k TYPE |V7k ENCLOSURE SN |v7K FW |V7k failed HDDs |V7k CONSOLE |DD MODEL |DD SERIAL |DD OS |DD DISK STATUS |DD UPTIME
 FARTS |sgu3a |10.1.1.1 |10.4.33.1 |DPM3 PFS-379/380 |See IPMI FRU |5.4 |2.6.18-164.2.1.el5PAE |i686 |6.0.2 | Thu Dec 15 2011 |4.100.0 |10.2.0.3.0 |10.2.0.3.0 |NA |NA |1.4.2 |4019116 |2 |2 |NA |T7400Core(TM)2 |120.0GB | |NA |DPM3 NA |1.00.08 |8192 |8192 |1155 days |1.9.3 2.0.1e 1.48.105 |NA |NA |NA |NA |NA |NA |NA |NA |NA |NA |NA |NA |NA |
 FARTS |sgu3b |10.1.1.2 |10.4.33.1 |DPM3 PFS-379/380 |See IPMI FRU |5.4 |2.6.18-164.2.1.el5PAE |i686 |6.0.2 | Thu Dec 15 2011 |4.100.0 |10.2.0.3.0 |10.2.0.3.0 |NA |NA |1.4.2 |4019116 |2 |2 |NA |T7400Core(TM)2 |120.0GB | |NA |DPM3 NA |1.00.08 |8192 |8192 |233 days |1.9.3 2.0.1e 1.48.105 |NA |NA |NA |NA |NA |NA |NA |NA |NA |NA |NA |NA |NA |
```
You can print necessary inventory data only:
``` shell
FARTS-UPM1a:upm1:# ./linux_hw_au.sh urp | awk -F '|' '{print $2"|"$5"|"$6}' 
HOSTNAME |HW TYPE                 |HW SN
    urp1 |IBM eServer BladeCenter |OLOLO
    urp2 |IBM eServer BladeCenter |OLOLO1
    urp3 |DPM3 PFS-379/380        |See IPMI FRU
FARTS-UPM1a:upm1:#
```
Or forward output into the file for further analysis:
``` shell
CSCOM-UPM1a:upm1:# ./linux_hw_au.sh dslu FARTS > FARTS.LINUX.`date +’%d.%m.%Y'`.csv 
CSCOM-UPM1a:upm1:# ls -lrt *.csv
-rw-r--r-- 1 root root 6310 Jan 20 22:36 FARTS.LINUX.20.01.2015.csv 
FARTS-UPM1a:upm1:# wc -l FARTS.LINUX.20.01.2015.csv
42 FARTS.LINUX.20.01.2015.csv
FARTS-UPM1a:upm1:#
```

AIX HOSTS INVENTORY
-------------------
To run Hardware Inventory checks against any Linux-based servers you have to execute `aix_hw_au.sh` script.
For help information, run `aix_hw_au.sh` without any keys:
``` shell
FARTS-UPM1a:upm1:# ./aix_hw_au.sh
   Runs Hardware Inventory checks against any AIX-based servers.
Usage: ./aix_hw_au.sh HOSTNAME SITE_ID Where:
      HOSTNAME is server to run inventory on or mask for the group of hosts from the /etc/hosts
      SITE_ID is optional parameter, will be inserted as first column of output. PROD_SITE is used
      by default
     Examples:
      ./aix_hw_au.sh sdp1b FARTS
      ./aix_hw_au.sh sdp FARTS_PROD
      ./aix_hw_au.sh FARTS_TEST
FARTS-UPM1a:upm1:#
```
Once you read all the help, you can execute `aix_hw_au.sh` script as superuser. Beware the script will not save any data to .CSV files, it will send all the output, about every server to console:
``` shell
FARTS-UPM1a:upm1:# ./aix_hw_au.sh sdp1 FARTS
  SITE |HOSTNAME |HW TYPE |SYSTEM MODEL |SERIAL |NGSCORE |DBCORE |ORACLE DB |ORACLE CLI |UP VERSION |JAVA VERSION |FIRMWARE |AIX OS LEVEL |BLU MODEL |BLU SERIAL |NSR LICENSE EXP |NETWORKER VERSION |FCSWA MODEL |FCSWA SN |FCSWA FW LEVEL |FCSWB MODEL |FCSWA SN |FCSWB FW LEVEL |EMC MODEL |EMC SERIAL |EMC FLARE |V7k MODEL |V7k TYPE |V7k ENCLOSURE SN |v7K FW |V7k failed HDDs |V7k CONSOLE |V7k2F MODEL |V7k2F TYPE |V7k2F ENCLOSURE SN |v7K2F FW |V7k2F failed SSDs |V7k2F CONSOLE |CLUST IP |NODE IP |HMC IP |LPAR INFO |AUTO RESTART |CPU CLOCK |NUM OF CPU |RAM SIZE |GOOD RAM SIZE |NUM OF RAM MODULES |SIZE OF RAM MODULES(MB) |PAGE SIZE |COUNT ERRPT | UNIQ ERRPT |UPTIME |
FARTS |sdp1a |POWER8 |IBM,8284-22A |OLOLO |V7.2.4 |4.56.0 |11.2.0.4.191015 |Not installed |Not installed |not |sys0!system:SV860_205 (t) SV860_205 (p) SV860_205 (t) |7200-03-03-1913 |IBMULT3580-HH7 |116B2DE05B |No Exp Date |NA| | | | | | |NA |NA |NA |NA |NA |NA |NA |       0  |NA |IBM FlashSystem 900 |control 9843-AE3  |13BG06X  |1.6.1.0 |0  |10.1.1.122:443 |10.1.1.138 | |NA|1 78-D13BX |true |3891 MHz |12 |253952 MB |253952 MB |8 |0032768 0032768 0032768 0032768 0032768 0032768 0032768 0032768  |s 4 KB m 64 KB  |32 |1 |329days |
FARTS |sdp1b |POWER8 |IBM,8284-22A |OLOLO |V7.2.4 |same2a |11.2.0.4.191015 |Not installed |Not installed |not |sys0!system:SV860_205 (t) SV860_205 (p) SV860_205 (t) |7200-03-03-1913 |IBMULT3580-HH7 |116B2DE05B |No Exp Date | | same as on node A |same as on node A | |same as on node A |same as on node A | |NA |NA |NA |same as on node A |same as on node A |same as on node A |same as on node A |same as on node A |same as on node A |same as on node A |same as on node A |same as on node A |same as on node A |same as on node A |same as on node A |10.4.19.138 | |NA|1 78-D13CX |true |3891 MHz |12 |253952 MB |253952 MB |8 |0032768 0032768 0032768 0032768 0032768 0032768 0032768 0032768 |s 4 KBm64KB |32|1|329days|
FARTS-UPM1a:upm1:#
```
You can print necessary inventory data only:
``` shell
upm1:# ./aix_hw_au.sh sdp | awk -F '|' '{print $2"|"$3"|"$44"|"$45"|"$46}' 
HOSTNAME |HW TYPE |CPU CLOCK |NUM OF CPU |RAM SIZE
sdp1a    |POWER8  |3891 MHz  |12         |253952 MB
...
sdp9b    |POWER8  |3891 MHz  |6          |186624 MB
FARTS-UPM1a:upm1:#
```
Or forward output into the file for further analysis:
``` shell
FARTS-UPM1a:upm1:# ./aix_hw_au.sh sdp FARTS > FARTS.AIX.`date +’%d.%m.%Y'`.csv 
FARTS-UPM1a:upm1:# ls -lrt *.csv
-rw-r--r-- 1 root root 6310 Jan 20 22:43 FARTS.AIX.20.01.2015.csv 
FARTS-UPM1a:upm1:# wc -l FARTS.AIX.20.01.2015.csv
14 FARTS.AIX.20.01.2015.csv
FARTS-UPM1a:upm1:#
```

HOW TO IMPORT .CSV Inventory file into EXCEL
--------------------------------------------

To import Inventory data from your .CSV file open Excel and go to `Data > From Text/CSV`:
![image](https://i.imgur.com/XYVIAmc.png)

Choose your .CSV file and press `“Open”` - new window will appear.
In new window choose `--Custom--` as a delimiter, from the list, enter pipe (`|`) in the field right below and then press `“Load”`.
![image](https://i.imgur.com/8A7JSnw.png)

The new Tab will be opened with your data.

#Thats all folks!
