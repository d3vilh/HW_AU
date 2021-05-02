Hardware Audit tool for Comverse One systems.
=============================================
Runs audit for all AIX and Linux servers and provides CSV file as result. 

PREREQUISITES
--------------
* Require Bash 3 version or higher on the host server (`bash --version`) 
* The /etc/hosts file on the host server should be reviewed before the first run
* SSH password-less access needs be configured across all UNIX servers (Linux and AIX). If this configuration is missed the utility will ask for the password for every server where no ssh certificates is present
* For IBM v7000 and fs900 storages, ssh password-less access needs to be present on SDP_A node to both storage enclosures(active and stby.). This is default configuration.
* The Hardware Inventory tool support any Linux or AIX versions on the remote servers by default. However, Site specific configuration should be done for audit.run script.
At the moment HW Inventory tool officially supports UCELL and all VEON (Russia + CIS) Production sites only.


PREPARATION
-----------
**1. The `/etc/hosts` file** on the host server should be ready to run inventory, as it takes servers list from the host server `/etc/hosts` file.
The scripts uses special filters to avoid running inventory on the same host several times. As addition cause you can add special filter to exclude not necessary servers from the inventory list by adding the line #audit_exclude for every `/etc/hosts` server record. For example:

```
VIP_DR:oam1a:/root# grep audit_exclude /etc/hosts 
10.31.189.112 upmdb upmdb_vip #audit_exclude
10.31.189.112 EM_REPOSITORY orac-upmdb upmdb #audit_exclude
```
**FOR BASIC INVENTORY** - skip preparation for IBM Storages and CISCO FCSs

**2. For IBM v7000** add san_console information into the SDP /etc/hosts (both nodes):
```
DR-SDP1a:sdp1:/# grep -i san /etc/hosts 
10.31.184.125 san_console
10.31.184.138 v7000-1a san1 
10.31.184.139 v7000-1b san2
```
The san_console is an IBM storage enclosures VIP interface. Which can be obtained from the storage active enclosure node (password-less access setup for SDP_A only):
```
DR-SDP1a:sdp1:/# ssh superuser@san_console lssystem | grep console 
console_IP 10.31.184.125:443
DR-SDP1a:sdp1:/#
```

**3. For IBM fs900** add san_console_flash information into the SDP `/etc/hosts` (both nodes):
```
Central-SDP23:sdp1:/# grep -i san_console /etc/hosts 
192.168.89.39 san_storage-23 san1 san_console 
192.168.89.45 san_flash-23 san2 san_console_flash 
Central-SDP23:sdp1:/#
```
The san_console_flash is an IBM flash storage enclosures VIP interface. This information can be obtained from the storage active node enclosure (console password-less access setup for SDP_A only by default):
```
Central-SDP23:sdp1:/# ssh superuser@san_console_flash lssystem | grep console 
console_IP 192.168.89.45:443
Central-SDP23:sdp1:/#
```

**4. Beware that to some POWER8 SDPs both type of the storages** (v7000 and fs900) can be connected to one SDP server (different VGs are located on different storages). Be sure that you have both san_console and san_console_flash IP addresses in /etc/hosts file on both SDP_A and SDP_B nodes for this type of servers.

5. Double check that SDP_A known_hosts file contains records for new san_console and san_console_flash hosts:
```
CEN-SDP23a:sdp1:/# ssh superuser@san_console 'lssystem'| grep code_level 
code_level 7.8.1.10 (build 135.9.1905291321000)
CEN-SDP23a:sdp1:/# ssh superuser@san_console_flash 'lssystem'| grep code_level 
code_level 7.8.1.10 (build 135.9.1905291321000)
CEN-SDP23a:sdp1:/#
```

**6. For CISCO FCS** (Nexus modules only) create special inventory user and configure password-less access for SDP_A node on fcswa and fcswb FCSs:
```
Central-SDP23:sdp1:/# grep -i fcsw /etc/hosts 
192.168.89.57 fc-sw23a fcswa fcs23a 
192.168.89.58 fc-sw23b fcswb fcs23b
Central-SDP23:sdp1:/#
```
Login from SDP_A node to fcswa as admin user and list all connected users to define correct SDP_A IP address:
```
FCS-23A# show users
NAME LINE TIME IDLE PID COMMENT
audit pts/0 Jan 21 20:37 . 6669 (192.168.89.56) session=ssh * FCS-23A#
```
Copy SDP_A RSA certificate to fcswa node (use IP defined on previous step):
```
FCS-23A# copy sftp://root@192.168.89.56/.ssh/id_rsa.pub id_rsa.pub Confirm certificate now exists on CISCO bootflash device:
FCS-23A# dir ...
             391    Mar 20 17:27:44 2019  id_rsa.pub
      ...
FCS-23A#
```
Create new audit user with reduced access permissions and stick RSA certificate to it:
```
FCS-23A# conf t
FCS-23A(config)# username audit password **Blah-Blah-Blah** role network-operator
 8
Hardware Inventory tool for C1 CV UCELL System. ver.1.0
FCS-23A(config)# username audit sshkey file bootflash:id_rsa.pub 
FCS-23A(config)# end
FCS-23A#
```
Confirm new user has been created with reduced permissions role and RSA certificate:
```
FCS-23A# show user-account audit user:audit
                this user account has no expiry date
                roles:network-operator
                ssh public key: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCxFUEqKCuvQiSE0
        ogU2oNplgN9caBmOUOQ556zD4PLzGS5SzBlah-Blah-Blah...
        FCS-23A#
```
Save new CISCO configuration:
```
FCS-23A# copy run start
# [########################################] 100% # Copy complete.
FCS-23A# exit
```
**Perform the same steps for SDP_A but from `fcswb (the second)` switch.**

Confirm password-less access is configured for both fcswa and fcswb switches from SDP_A node:
```
sdp23a:/# ssh -q audit@fcswa 'sh inventory' | head -1 | awk '{print $4,$5}'; MDS 9148S
sdp23a:/# ssh -q audit@fcswb 'sh inventory' | head -1 | awk '{print $4,$5}'; MDS 9148S
sdp23a:/#
```

FULL SITE INVENTORY
-------------------
To run hardware inventory across all the onsite servers you have to execute audit.run script
as superuser with short site name:
```
COSCOM-UPM1a:upm1:# ./audit.run UCELL
Keep an eye on the progress. Human input might be required.
   Running HW Inventory on following units:
   SGU, DGU, SLU, DSLU, CRMOMAPP, ... CMVOEM, UPM, UPMDB, OAMAPP, SDP, CPM, WPDB, BF, ADMIN
   PROGRESS: 70%  [################################..............] RUNNING ON: UPM&DB
For help information - fire audit.run without any keys: COSCOM-UPM1a:upm1:# ./audit.run
   Runs Hardware Inventory checks across all onsite units.
Usage: ./audit.run SITE_ID
Where SITE_ID is short site name. AIX and LINUX inventory scripts will be updated
  with this short name on first audit.run execution.
    Examples:
      ./audit.run UCELL
      ./audit.run UCELL_PROD
      ./audit.run UCELL_TEST
    Prerequisites:
      aix_hw_au.sh - runs Hardware Inventory checks against any AIX-based servers.
      linux_hw_au.sh - runs Hardware Inventory checks against any Linux-based servers.
Be aware that SANbox and EMCds FCSs checks is deprecated in this version, as obsolete HW 
COSCOM-UPM1a:upm1:#
```
As a result of this execution you’ll have two .CSV files. First with Linux based servers inventory, second with AIX based servers inventory information:
```
COSCOM-UPM1a:upm1:# ls -rlt
-rwxrwxrwx 1 root root 5319 Jan 21 19:40 audit.run
-rwxrwxrwx 1 root root 15880 Jan 21 21:32 linux_hw_au.sh 
-rwxrwxrwx 1 root root 12436 Jan 21 21:32 aix_hw_au.sh
-rw-r--r-- 1 root root 87596 Jan 21 21:43 UCELL.LINUX_HW_LIST.csv 
-rw-r--r-- 1 root root 20161 Jan 21 21:47 UCELL.AIX_HW_LIST.csv 
COSCOM-UPM1a:upm1:#
```
Both CSV files will contain all the inventory data with pipe (|) symbol used as the columns delimiter:
```
COSCOM-UPM1a:upm1:# head -2 YAR.LINUX_HW_LIST.csv
SITE |HOSTNAME |IP ADDR |ROUTE |HW TYPE |HW SN |LNX SCORE |KERNEL |HW ARCH |APP VERSION |APP INSTALL DATE(M/D/Y) |UP VERSION |ORA CLI |ORA DB |TT DB |WL VERSION |JAVA VER |RAM |CORES |THREADS |ENA CORES |CPU |HDD SIZE |HDD MODEL |HDD HEALTH |ACTIVE UEFI BANK |UEFI/BIOS VERSION |FILE-MAX (sysctl.conf) |FILE-LIMIT (ulimit -n)|UPTIME |NIC DRVs |EMC MODEL |EMC SERIAL |EMC FLARE |V7k MODEL |V7k TYPE |V7k ENCLOSURE SN |v7K FW |V7k failed HDDs |V7k CONSOLE |DD MODEL |DD SERIAL |DD OS |DD DISK STATUS |DD UPTIME YAR |sgu1a |10.31.184.100 |10.31.184.1 |ProLiant BL460c Gen8 |CZJ34204BT |6.2.1 | 2.6.32-220.el6.i686 |i686 |7.0.5 | Mon Apr 10 2017 |4.120.0 |11.2.0.3.0 |NA |NA |NA | 1.6.0_31 |3983136 |6 |12 |6 |E5-2620Xeon(R) |300.0GB |HP LOGICAL VOLUME |OK |HP NA | 1.51 | 20000 |8192 |327 days |2.1.11 2.7.0.3 1.70.00-0 |NA |NA |NA |NA |NA |NA |NA |NA |NA |NA |NA |NA |NA |
COSCOM-UPM1a:upm1:#
```
