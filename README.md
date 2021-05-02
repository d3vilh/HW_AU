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