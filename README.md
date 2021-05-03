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
CELCO:oam1a:/root# grep audit_exclude /etc/hosts 
10.1.1.112 upmdb upmdb_vip #audit_exclude
10.1.1.112 EM_REPOSITORY orac-upmdb upmdb #audit_exclude
```
**FOR BASIC INVENTORY** - skip preparation for IBM Storages and CISCO FCSs

**2. For IBM v7000** add san_console information into the SDP `/etc/hosts` (both nodes):
``` shell
CELCO-SDP1a:sdp1:/# grep -i san /etc/hosts 
10.1.1.125 san_console
10.1.1.138 v7000-1a san1 
10.1.1.139 v7000-1b san2
```
The san_console is an IBM storage enclosures VIP interface. Which can be obtained from the storage active enclosure node (password-less access setup for SDP_A only):
``` shell
CELCO-SDP1a:sdp1:/# ssh superuser@san_console lssystem | grep console 
console_IP 10.1.1.125:443
CELCO-SDP1a:sdp1:/#
```

**3. For IBM fs900** add san_console_flash information into the SDP `/etc/hosts` (both nodes):
``` shell
CELCO-SDP23:sdp1:/# grep -i san_console /etc/hosts 
10.1.1.39 san_storage-23 san1 san_console 
10.1.1.45 san_flash-23 san2 san_console_flash 
CELCO-SDP23:sdp1:/#
```
The san_console_flash is an IBM flash storage enclosures VIP interface. This information can be obtained from the storage active node enclosure (console password-less access setup for SDP_A only by default):
``` shell
CELCO-SDP23:sdp1:/# ssh superuser@san_console_flash lssystem | grep console 
console_IP 10.1.1.45:443
CELCO-SDP23:sdp1:/#
```

**4. Beware that to some POWER8 SDPs both type of the storages** (v7000 and fs900) can be connected to one SDP server (different VGs are located on different storages). Be sure that you have both `san_console` and `san_console_flash` IP addresses in `/etc/hosts` file on **both SDP_A and SDP_B nodes** for this type of servers.

**5. Double check** that SDP_A `known_hosts` file contains records for new san_console and `san_console_flash` hosts:
``` shell
CELCO-SDP23a:sdp1:/# ssh superuser@san_console 'lssystem'| grep code_level 
code_level 7.8.1.10 (build 135.9.1905291321000)
CELCO-SDP23a:sdp1:/# ssh superuser@san_console_flash 'lssystem'| grep code_level 
code_level 7.8.1.10 (build 135.9.1905291321000)
CELCO-SDP23a:sdp1:/#
```

**6. For CISCO FCS** (Nexus modules only) create special inventory user and configure password-less access for SDP_A node on fcswa and fcswb FCSs:
``` shell
CELCO-SDP23:sdp1:/# grep -i fcsw /etc/hosts 
10.1.1.57 fc-sw23a fcswa fcs23a 
10.1.1.58 fc-sw23b fcswb fcs23b
CELCO-SDP23:sdp1:/#
```
Login from SDP_A node to fcswa as admin user and list all connected users to define correct SDP_A IP address:
``` shell
CELCO-FCS-23A# show users
NAME LINE TIME IDLE PID COMMENT
audit pts/0 Jan 21 20:37 . 6669 (10.1.1.56) session=ssh * CELCO-FCS-23A#
```
Copy SDP_A RSA certificate to fcswa node (use IP defined on previous step):
``` shell
CELCO-FCS-23A# copy sftp://root@10.1.1.56/.ssh/id_rsa.pub id_rsa.pub 
```
Confirm certificate now exists on CISCO bootflash device:
``` shell
CELCO-FCS-23A# dir ...
             391    Mar 20 17:27:44 2019  id_rsa.pub
      ...
CELCO-FCS-23A#
```
Create new audit user with reduced access permissions and stick RSA certificate to it:
``` shell
CELCO-FCS-23A# conf t
CELCO-FCS-23A(config)# username audit password Blah-Blah-Blah role network-operator
CELCO-FCS-23A(config)# username audit sshkey file bootflash:id_rsa.pub 
CELCO-FCS-23A(config)# end
CELCO-FCS-23A#
```
Confirm new user has been created with reduced permissions role and RSA certificate:
``` shell
CELCO-FCS-23A# show user-account audit 
        user:audit
        this user account has no expiry date
        roles:network-operator
        ssh public key: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCxFUEqKCuvQiSE0
        ogU2oNplgN9caBmOUOQ556zD4PLzGS5SzBlah-Blah-Blah...
CELCO-FCS-23A#
```
Save new CISCO configuration:
``` shell
CELCO-FCS-23A# copy run start
# [########################################] 100% # Copy complete.
CELCO-FCS-23A# exit
```
**Perform the same steps for SDP_A but from `fcswb (the second)` switch.**

Confirm password-less access is configured for both fcswa and fcswb switches from SDP_A node:
``` shell
CELCO-sdp23a:/# ssh -q audit@fcswa 'sh inventory' | head -1 | awk '{print $4,$5}'; 
MDS 9148S
CELCO-sdp23a:/# ssh -q audit@fcswb 'sh inventory' | head -1 | awk '{print $4,$5}'; 
MDS 9148S
sdp23a:/#
```

FULL SITE INVENTORY
-------------------
To run hardware inventory across all the onsite servers you have to execute `audit.run` script
as superuser with short site name:
``` shell
CELCO-UPM1a:upm1:# ./audit.run CELCO
Keep an eye on the progress. Human input might be required.
   Running HW Inventory on following units:
   SGU, DGU, SLU, DSLU, CRMOMAPP, ... CMVOEM, UPM, UPMDB, OAMAPP, SDP, CPM, WPDB, BF, ADMIN
   PROGRESS: 70%  [################################..............] RUNNING ON: UPM&DB
```
For help information - fire `audit.run` without any keys: 
``` shell
CELCO-UPM1a:upm1:# ./audit.run
   Runs Hardware Inventory checks across all onsite units.
Usage: ./audit.run SITE_ID
Where SITE_ID is short site name. AIX and LINUX inventory scripts will be updated
  with this short name on first audit.run execution.
    Examples:
      ./audit.run CELCO
      ./audit.run CELCO_PROD
      ./audit.run CELCO_TEST
    Prerequisites:
      aix_hw_au.sh - runs Hardware Inventory checks against any AIX-based servers.
      linux_hw_au.sh - runs Hardware Inventory checks against any Linux-based servers.
Be aware that SANbox and EMCds FCSs checks is deprecated in this version, as obsolete HW 
CELCO-UPM1a:upm1:#
```
As a result of this execution you’ll have two .CSV files. First with Linux based servers inventory, second with AIX based servers inventory information:
``` shell
CELCO-UPM1a:upm1:# ls -rlt
-rwxrwxrwx 1 root root 5319 Jan 21 19:40 audit.run
-rwxrwxrwx 1 root root 15880 Jan 21 21:32 linux_hw_au.sh 
-rwxrwxrwx 1 root root 12436 Jan 21 21:32 aix_hw_au.sh
-rw-r--r-- 1 root root 87596 Jan 21 21:43 CELCO.LINUX_HW_LIST.csv 
-rw-r--r-- 1 root root 20161 Jan 21 21:47 CELCO.AIX_HW_LIST.csv 
CELCO-UPM1a:upm1:#
```
Both CSV files will contain all the inventory data with pipe (`|`) symbol used as the columns delimiter:
``` shell
CELCO-UPM1a:upm1:# head -2 YAR.LINUX_HW_LIST.csv
SITE |HOSTNAME |IP ADDR    |ROUTE    |HW TYPE              |HW SN |LNX SCORE |KERNEL               |HW ARCH |APP VERSION |APP INSTALL DATE(M/D/Y) |UP VERSION |ORA CLI    |ORA DB |TT DB |WL VERSION |JAVA VER  |RAM     |CORES |THREADS |ENA CORES |CPU            |HDD SIZE |HDD MODEL         |HDD HEALTH |ACTIVE UEFI BANK |UEFI/BIOS VERSION |FILE-MAX (sysctl.conf) |FILE-LIMIT (ulimit -n)|UPTIME   |NIC DRVs                 |EMC MODEL |EMC SERIAL |EMC FLARE |V7k MODEL |V7k TYPE |V7k ENCLOSURE SN |v7K FW |V7k failed HDDs |V7k CONSOLE |DD MODEL |DD SERIAL |DD OS |DD DISK STATUS |DD UPTIME 
YAR  |sgu1a    |10.1.1.100 |10.1.1.1 |ProLiant BL460c Gen8 |OLOLO |6.2.1     | 2.6.32-220.el6.i686 |i686    |7.0.5       | Mon Apr 10 2017        |4.120.0    |11.2.0.3.0 |NA     |NA    |NA         | 1.6.0_31 |3983136 |6     |12      |6         |E5-2620Xeon(R) |300.0GB  |HP LOGICAL VOLUME |OK         |HP NA            | 1.51             | 20000                 |8192                  |327 days |2.1.11 2.7.0.3 1.70.00-0 |NA        |NA         |NA        |NA        |NA       |NA               |NA     |NA              |NA          |NA       |NA        |NA    |NA | NA
CELCO-UPM1a:upm1:#
```

LINUX HOSTS INVENTORY
---------------------
To run Hardware Inventory checks against any Linux-based servers you have to execute `linux_hw_au.sh` script.
For help information, run `linux_hw_au.sh` without any keys:
``` shell
CELCO-UPM1a:upm1:# ./linux_hw_au.sh
   Runs Hardware Inventory checks against any Linux-based servers.
Usage: ./linux_hw_au.sh HOSTNAME SITE_ID Where:
      HOSTNAME is server to run inventory on or mask for the group of hosts from the /etc/hosts
      SITE_ID is optional parameter, will be inserted as first column of output. PROD_SITE is used
      by default
     Examples:
      ./linux_hw_au.sh sgu21b CELCO
      ./linux_hw_au.sh slu CELCO_PROD
      ./linux_hw_au.sh sgu23
CELCO-UPM1a:upm1:#
```
Once you read all the help, you can execute `linux_hw_au.sh` script as superuser.
Beware the script will not save any data to .CSV files, it will send all the output, about every server to console:
``` shell
CELCO-UPM1a:upm1:# ./linux_hw_au.sh sgu3 CELCO
  SITE |HOSTNAME |IP ADDR  |DEF GW   |HW TYPE                  |HW SN        |LNX SCORE |KERNEL                     |HW ARCH |APP VERSION |APP INSTALL DATE(M/D/Y) |UP VERSION |ORA CLI    |ORA DB      |ORA TT DB   |WL VERSION |JAVA VER |RAM      |CORES |THREADS |ENA CORES |CPU            |HDD SIZE |HDD MODEL         |HDD HEALTH |ACTIVE UEFI BANK |UEFI/BIOS VERSION   |FILE-MAX (sysctl.conf) |FILE-LIMIT (ulimit -n)|UPTIME    |NIC DRVs                  |EMC MODEL |EMC SERIAL     |EMC FLARE      |V7k MODEL          |V7k TYPE          |V7k ENCLOSURE SN |v7K FW  |V7k failed HDDs |V7k CONSOLE      |DD MODEL       |DD SERIAL      |DD OS          |DD DISK STATUS |DD UPTIME
 CELCO |sgu3a    |10.1.1.1 |1.4.33.1 |DPM3 PFS-379/380         |See IPMI FRU |5.4       |2.6.18-164.2.1.el5PAE      |i686    |6.0.2       | Thu Dec 15 2011        |4.109.3    |10.2.0.3.0 |10.2.0.3.0  |NA          |NA         |1.4.2    |4019116  |2     |2       |NA        |T7400Core(TM)2 |120.0GB  |SEAGATE-MDB       |OK         |DPM3 NA          |1.00.08             |8192                   |8192                  |1155 days |1.9.3 2.0.1e 1.48.105     |NA        |NA             |NA             |NA                 |NA                |NA               |NA      |NA              |NA               |NA             |NA             |NA             |NA             |NA
 CELCO |upm1     |10.1.1.5 |1.4.33.1 |INTEL BALLENGER T5000PAL |AZD666OLOLO  |2.0.7.22  |2.6.18-164.el5PAE          |i686    |3.8.4.2     | Wed Jun 04 2017        |4.109.3    |NA         |10.2.0.5.0a |NA          |NA         |1.4.2    |16622832 |4     |4       |NA        |5128Xeon(R)    |73.5GB   |FUJITSUMBB2073RC  |OK         |BALLENGER NA     |10.0                |131072                 |65536                 |306 days  |1.9.3 2.0.1e 1.48.105     |CX300     |CK2000666OLOLO |2.26.300.5.020 |NA                 |NA                |NA               |NA      |NA              |NA               |NA             |NA             |NA             |NA             |NA
 CELCO |upmdb1a  |10.1.1.3 |1.4.33.1 |ProLiant BL460c Gen8     |CZD666OLOLO  |6.2.2     |2.6.32-220.46.1.el6.x86_64 |x86_64  |3.8.4.2     | Fri Sep 01 2015        |2.0.0      |NA         |11.2.0.4.12 |NA          |NA         |1.6.0_31 |32839312 |6     |12      |6         |E5-2620Xeon(R) |300.0GB  |HP LOGICAL VOLUME |OK         |HP NA            |1.51                |200006815744           |65536                 |585 days  |2.1.11 2.7.0.3 1.70.00-0  |NA        |NA             |NA             |NA                 |NA                |NA               |NA      |NA              |NA               |DD2200         |FLD221OLOLOSHA |5.5.0.9-471508 |Normal         |32 days
 CELCO |oam1     |10.1.1.4 |1.4.33.1 |ProLiant BL460c Gen8     |CZJ666OLOLO  |6.2.1     |2.6.32-220.el6.x86_64      |x86_64  |3.8.4.2     | Wed Oct 06 2017        |4.110.2    |11.2.0.3.0 |NA          |NA          |NA         |1.6.0_31 |16292520 |6     |12      |6         |E5-2620Xeon(R) |300.0GB  |HP LOGICAL VOLUME |OK         |HP NA            |1.51                |20000                  |8192                  |35 days   |2.1.11 2.7.0.3 1.70.00-0  |NA        |NA             |NA             |IBM Storwize V7000 |control 2076-524  |control 7LOLOKA  |7.4.0.2 |0               |10.1.1.99:443    |NA             |NA             |NA             |NA             |NA
 CELCO |sapi6    |10.1.1.2 |1.4.33.1 |BladeCenter HS22 -[7Z5]- |06W666OLOLO  |5.4       |2.6.18-164.2.1.el5         |x86_64  |3.8.4.2     | Thu Oct 01 2015        |4.110.2    |10.2.0.1.0 |10.2.0.3.0  |NA          |10.3.0.0   |1.4.2    |12142660 |8     |16      |4+4       |E5620Xeon(R)   |600.1GB  |IBM-ESXSMBF2600RC |OK         |Primary          |P9E165BUS-1.29-     |5000                   |8192                  |3 days    |2.0.24b 2.6.2.4c 1.62.16  |NA        |NA             |NA             |NA                 |NA                |NA               |NA      |NA              |NA               |NA             |NA             |NA             |NA             |NA
 CELCO |slu14    |10.1.1.8 |1.4.33.1 |ProLiant BL460c Gen8     |CZD666OLOLO  |5.8       |2.6.18-400.1.1.el5PAE      |i686    |3.8.4.2     | Wed Apr 22 2017        |4.110.2    |10.2.0.1.0 |10.2.0.3.0  |NA          |NA         |1.4.2    |33111736 |8     |16      |8         |E5-2658Xeon(R) |600.0GB  |HP EG0600FBVFP    |OK         |HP NA            |1.51                |65000                  |65000                 |271 days  |2.1.11 2.7.2.2 1.72.51-0  |NA        |NA             |NA             |NA                 |NA                |NA               |NA      |NA              |NA               |NA             |NA             |NA             |NA             |NA
 CELCO |eci16    |10.1.1.9 |1.4.33.1 |ProLiant BL460c Gen9     |CZD666OLOLO  |6.6       |2.6.32-504.16.2.el6.x86_64 |x86_64  |3.8.4.2     | Wed May 06 2017        |2.0.0      |11.2.0.3.0 |NA          |NA          |NA         |1.6.0_31 |32751916 |6     |12      |6         |E5-2620Xeon(R) |600.1GB  |HP LOGICAL VOLUME |OK         |HP NA            |2.50                |65000                  |65000                 |133 days  |2.2.5l 2.10.1.0 1.710.71  |NA        |NA             |NA             |NA                 |NA                |NA               |NA      |NA              |NA               |NA             |NA             |NA             |NA             |NA
 CELCO |dtr12    |10.1.1.4 |1.4.33.1 |ProLiant DL360 Gen10     |CZD666OLOLO  |6.9       |2.6.32-696.el6.x86_64      |x86_64  |5.5.4       | Mon Dec 07 2017        |4.120.0    |11.2.0.5.0 |NA          |11.2.2.8.12 |NA         |1.6.0_31 |32543264 |4     |8       |4         |5122Xeon(R)    |300.0GB  |HP EG000300JWSJP  |OK         |HP NA            |FW: 2.14 BIOS: 2.34 |65000                  |65000                 |176 days  |2.2.6 2.7.10.1 1.712.30-0 |NA        |NA             |NA             |NA                 |NA                |NA               |NA      |NA              |NA               |NA             |NA             |NA             |NA             |NA
```
You can print necessary inventory data only:
``` shell
CELCO-UPM1a:upm1:# ./linux_hw_au.sh urp | awk -F '|' '{print $2"|"$5"|"$6}' 
HOSTNAME |HW TYPE                  |HW SN
    urp1 |IBM eServer BladeCenter  |OLOLO
    urp2 |BladeCenter HS22 -[7Z5]- |OLOLO1
    urp3 |DPM3 PFS-379/380         |See IPMI FRU
CELCO-UPM1a:upm1:#
```
Or forward output into the file for further analysis:
``` shell
CELCO-UPM1a:upm1:# ./linux_hw_au.sh dslu CELCO > CELCO.LINUX.`date +’%d.%m.%Y'`.csv 
CELCO-UPM1a:upm1:# ls -lrt *.csv
-rw-r--r-- 1 root root 6310 Jan 20 22:36 CELCO.LINUX.20.01.2015.csv 
CELCO-UPM1a:upm1:# wc -l CELCO.LINUX.20.01.2015.csv
42 CELCO.LINUX.20.01.2015.csv
CELCO-UPM1a:upm1:#
```

AIX HOSTS INVENTORY
-------------------
To run Hardware Inventory checks against any Linux-based servers you have to execute `aix_hw_au.sh` script.
For help information, run `aix_hw_au.sh` without any keys:
``` shell
CELCO-UPM1a:upm1:# ./aix_hw_au.sh
   Runs Hardware Inventory checks against any AIX-based servers.
Usage: ./aix_hw_au.sh HOSTNAME SITE_ID Where:
      HOSTNAME is server to run inventory on or mask for the group of hosts from the /etc/hosts
      SITE_ID is optional parameter, will be inserted as first column of output. PROD_SITE is used
      by default
     Examples:
      ./aix_hw_au.sh sdp1b CELCO
      ./aix_hw_au.sh sdp CELCO_PROD
      ./aix_hw_au.sh CELCO_TEST
CELCO-UPM1a:upm1:#
```
Once you read all the help, you can execute `aix_hw_au.sh` script as superuser. Beware the script will not save any data to .CSV files, it will send all the output, about every server to console:
``` shell
CELCO-UPM1a:upm1:# ./aix_hw_au.sh sdp1 CELCO
 SITE |HOSTNAME |HW TYPE |SYSTEM MODEL |SERIAL |NGSCORE |DBCORE |ORACLE DB       |ORACLE CLIENT |UP VERSION |JAVA VERSION |FIRMWARE                                              |AIX OS LEVEL    |BLU MODEL       |BLU SERIAL |NSR LICENSE EXP |NETWORKER VERSION |FCSWA MODEL    |FCSWA SN    |FCSWA FW LEVEL |FCSWB MODEL    |FCSWA SN    |FCSWB FW LEVEL |EMC MODEL |EMC SERIAL     |EMC FLARE       |V7k MODEL          |V7k TYPE                                                                                     |V7k ENCLOSURE SN                                                              |v7K FW    |V7k failed HDDs |V7k CONSOLE     |V7k2F MODEL         |V7k2F TYPE       |V7k2F ENCLOSURE SN |v7K2F FW  |V7k2F failed SSDs |V7k2F CONSOLE  |CLUST IP   |NODE IP   |HMC IP    |LPAR INFO  |AUTO RESTART |CPU CLOCK |NUM OF CPU |RAM SIZE  |GOOD RAM SIZE |NUM OF RAM MODULES |SIZE OF RAM MODULES(MB)                                                                                                                                                                                                                        |PAGE SIZE      |COUNT ERRPT | UNIQ ERRPT |UPTIME
CELCO |sdp1a    |POWER8  |IBM,8284-22A |OLOLO  |V7.2.4  |4.56.0 |11.2.0.4.191015 |Not installed |4.110.2    |1.6.2        |sys0!system:SV860_205 (t) SV860_205 (p) SV860_205 (t) |7200-03-03-1913 |IBMULT3580-HH7  |31666OLOLO |No Exp Date     |NA                |cisco MDS 9124 |FOX15666LOL |5.0(1a)        |cisco MDS 9124 |FOX12666LOL |5.0(1a)        |NA        |NA             |NA              |NA                 |NA                                                                                           |NA                                                                            |NA        |0               |NA              |IBM FlashSystem 900 |control 9843-AE3 |1666LOL            |1.6.1.0   |0                 |10.1.1.122:443 |10.1.1.138 |10.1.1.32 |NA        |1 78-D13BX |true         |3891 MHz  |12         |253952 MB |253952 MB     |8                  |32768 32768 32768 32768 32768 32768 32768 32768                                                                                                                                                                                                |s 4 KB m 64 KB |32          |1           |329days
CELCO |sdp1b    |POWER8  |IBM,8284-22A |OLOLO  |V7.2.4  |same2a |11.2.0.4.191015 |Not installed |4.110.2    |1.6.2        |sys0!system:SV860_205 (t) SV860_205 (p) SV860_205 (t) |7200-03-03-1913 |IBMULT3580-HH7  |31666OLOLO |No Exp Date     |NA                |see node A     |see node A  |see node A     |see node A     |see node A  |see node A     |NA        |NA             |NA              |NA                 |NA                                                                                           |NA                                                                            |NA        |0               |NA              |see node A          |see node A       |see node A         |see node A|see node A        |see node A     |10.1.1.139 |10.1.1.33 |NA        |1 78-D13CX |true         |3891 MHz  |12         |253952 MB |253952 MB     |8                  |32768 32768 32768 32768 32768 32768 32768 32768                                                                                                                                                                                                |s 4 KB m 64 KB |32          |1           |329days
CELCO |sdp2b    |POWER5  |IBM,9117-570 |OLOLO  |V3.0.4  |3.5.50 |10.2.0.5.0      |Not installed |4.100.0    |1.5.0        |sys0!system:SF240_338 (t) SF240_332 (p) SF240_338 (t) |6100-06-01-1043 |IBMULTRIUM-TD3  |27666OLOLO |No Exp Date     |7.6.Build.142;    |               |            |               |               |            |               |CX3-40f   |CK2000666OLOLO |3.26.40.5.025   |NA                 |NA                                                                                           |NA                                                                            |NA        |NA              |NA              |NA                  |NA               |NA                 |NA        |NA                |NA             |10.1.1.140 |10.1.1.45 |NA        |1 06-9B300 |true         |1900 MHz  |8          |63872 MB  |63872 MB      |32                 |2048 2048 2048 2048 2048 2048 2048 2048 2048 2048 2048 2048 2048 2048 2048 2048 2048 2048 2048 2048 2048 2048 2048 2048 2048 2048 2048 2048 2048 2048 2048 2048                                                                                |s 4 KB m 64 KB |34          |2           |642days
CELCO |sdp3a    |POWER6  |IBM,9117-MMA |OLOLO  |V3.0.5  |4.35.0 |11.2.0.3.12     |Not installed |4.100.0    |1.5.0        |sys0!system:EM350_108 (t) EM350_108 (p) EM350_108 (t) |6100-06-01-1043 |IBMULTRIUM-TD3  |27666OLOLO |No Exp Date     |7.6.Build.142;    |NA             |NA          |NA             |NA             |NA          |NA             |CX3-40f   |CK2000666OLOLO |3.26.40.5.032   |NA                 |NA                                                                                           |NA                                                                            |NA        |NA              |NA              |NA                  |NA               |NA                 |NA        |NA                |NA             |10.1.1.141 |10.1.1.48 |10.1.1.88 |2 CEL-SDP3 |true         |4208 MHz  |8          |190464 MB |190464 MB     |48                 |4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096 4096|s 4 KB m 64 KB |43728       |5           |629days
CELCO |sdp10a   |POWER7  |IBM,8233-E8B |OLOLO  |V3.0.6  |4.56.0 |11.2.0.3.15     |Not installed |4.110.2    |1.5.0        |sys0!system:AL730_154 (t) AL730_154 (p) AL730_154 (t) |6100-09-03-1415 |HPUltrium4-SCSI |27666OLOLO |No Exp Date     |8.2.1.0.Build.681;|cisco MDS 9124 |FOX15666LOL |5.0(4c)        |cisco MDS 9124 |FOX15666LOL |5.0(4c)        |CX4-480   |CKM001666OLOLO |04.30.000.5.529 |NA                 |NA                                                                                           |NA                                                                            |NA        |NA              |NA              |NA                  |NA               |NA                 |NA        |NA                |NA             |10.1.1.142 |10.1.1.28 |NA        |1 06-4C53R |true         |3220 MHz  |8          |127744 MB |127744 MB     |8                  |16384 16384 16384 16384 16384 16384 16384 16384                                                                                                                                                                                                |s 4 KB m 64 KB |19          |2           |159days
CELCO |sdp23a   |POWER8  |IBM,8284-22A |OLOLO  |V3.0.11 |4.55.0 |11.2.0.4.5      |Not installed |4.100.0    |1.5.0        |sys0!system:SV860_118 (t) SV860_118 (p) SV860_118 (t) |6100-09-03-1415 |HPUltrium6-SCSI |27666OLOLO |No Exp Date     |8.2.1.0.Build.681;|cisco MDS 9148S|JPG21666LOL |6.2(17)        |cisco MDS 9148S|JPG21666LOL |6.2(17)        |NA        |NA             |NA              |IBM Storwize V7000 |expansion 2076-24F expansion 2076-24F control 2076-624 expansion 2076-24F expansion 2076-24F |expansion 71LOL expansion 71LOL control 71LOL expansion 71LOL expansion 71LOL |8.2.1.10  |0               |10.1.1.77:443   |NA                  |NA               |NA                 |NA        |NA                |NA             |10.1.1.143 |10.1.1.70 |NA        |1 78-2521X |true         |3891 MHz  |6          |189696 MB |189696 MB     |6                  |32768 32768 32768 32768 32768 32768                                                                                                                                                                                                            |s 4 KB m 64 KB |69          |3           |701days
CELCO |sdp23b   |POWER8  |IBM,8284-22A |OLOLO  |V3.0.11 |3.6.10 |11.2.0.4.5      |Not installed |4.100.0    |1.5.0        |sys0!system:SV860_118 (t) SV860_118 (p) SV860_118 (t) |6100-09-03-1415 |HPUltrium6-SCSI |27666OLOLO |No Exp Date     |8.2.1.0.Build.681;|see node A     |see node A  |see node A     |see node A     |see node A  |see node A     |NA        |NA             |NA              |see node A         |see node A                                                                                   |see node A                                                                    |see node A|see node A      |see node A      |see node A          |see node A       |see node A         |see node A|see node A        |see node A     |10.1.1.144 |10.1.1.71 |NA        |1 78-2523X |true         |3891 MHz  |6          |189696 MB |189696 MB     |6                  |32768 32768 32768 32768 32768 32768                                                                                                                                                                                                            |s 4 KB m 64 KB |69          |3           |701days
CELCO |sdp29a   |POWER9  |IBM,9009-22A |OLOLO  |V7.2.4  |4.55.0 |11.2.0.4.200414 |Not installed |4.100.0    |1.6.0        |sys0!system:VL930_048 (t) VL930_048 (p) VL930_048 (t) |7200-03-03-1913 |IBMULT3580-HH7  |11666OLOLO |No Exp Date     |NA                |cisco MDS 9148S|JPG23666LOL |8.1(1a)        |cisco MDS 9148S|JPG23666LOL |8.1(1a)        |NA        |NA             |NA              |NA                 |NA                                                                                           |NA                                                                            |NA        |NA              |NA              |IBM FlashSystem 900 |control 9843-AE3 |2666LOL            |1.6.1.0   |0                 |10.1.1.123:443 |10.1.1.145 |10.1.1.96 |NA        |1 78-580B0 |true         |3000 MHz  |8          |252928 MB |252928 MB     |8                  |32768 32768 32768 32768 32768 32768 32768 32768                                                                                                                                                                                                |s 4 KB m 64 KB |482         |2           |497days
CELCO-UPM1a:upm1:#
```
You can print necessary inventory data only:
``` shell
upm1:# ./aix_hw_au.sh sdp | awk -F '|' '{print $2"|"$3"|"$44"|"$45"|"$46}' 
HOSTNAME |HW TYPE |CPU CLOCK |NUM OF CPU |RAM SIZE
sdp1a    |POWER8  |3891 MHz  |12         |253952 MB
...
sdp99b   |POWER8  |3891 MHz  |6          |186624 MB
CELCO-UPM1a:upm1:#
```
Or forward output into the file for further analysis:
``` shell
CELCO-UPM1a:upm1:# ./aix_hw_au.sh sdp CELCO > CELCO.AIX.`date +’%d.%m.%Y'`.csv 
CELCO-UPM1a:upm1:# ls -lrt *.csv
-rw-r--r-- 1 root root 6310 Jan 20 22:43 CELCO.AIX.20.01.2015.csv 
CELCO-UPM1a:upm1:# wc -l CELCO.AIX.20.01.2015.csv
14 CELCO.AIX.20.01.2015.csv
CELCO-UPM1a:upm1:#
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
