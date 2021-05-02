#!/bin/bash
#/usr/bin/expect -f
# HSBU Hardware
# By Philipp Shilov @HWsupport 10.03.2017 v.1.1
  logfile=/tmp/HSBU_log.log
  echo "" > $logfile
  r_user=Netadmn9
  r_password="Incom9()"
  chocha_hsb="#"
  delat_krasivo=$1
printf "HOSTNAME |MODEL |MEMORY |SERIAL NUMBER |ROM |iOS IMAGE |UPTIME |RETURNED BY |CONF REG\n";
for host in $(grep -iE $delat_krasivo /etc/hosts|grep -viE '^ *#|farm|nortel|cajun|cluster|zbx|juniper|ure|sdp|ilo|not|shutdown|rctu|trsu'|awk {'print$3'}|sort|uniq);
do ping -c1 $host 1>/dev/null &&
expect <<++EOF++ >>${logfile} 2>&1
set timeout 1200
spawn ssh ${r_user}@${host}
expect "*assword*"
send "${r_password}\r\n"
expect "*${chocha_hsb}*"
send "sh version\r"
send " \r"
expect "*#*"
send "show running-config | in hostname\r"
expect "*hostname*"
send "exit\r"
expect ++EOF++
++EOF++
tricky_joe=`grep proc $logfile`;
if [ -n "$tricky_joe" ]; then
	for f in $logfile ; do
       ed -s -- "$f" <<<$',s/\r//g\nw' >/dev/null
    done
 grep hostname $logfile | grep -vE 'running-config|vty' | awk '{print $2}' | tr '\n' '|';
 grep processor $logfile | grep -v 'sh version'| awk '{print $2, $3"|" $8}' | tr '\n' '|';
 #PORTS COMENTED OUT
 #grep interface $logfile  | grep -iE "fast|giga|channel" | awk '{print $1}' | tr -d '/"' | tr '\n' '|';
 grep -i "board id" $logfile | grep -v 'sh version'| awk '{print $4}' | tr '\n' '|';
 grep ROM $logfile | grep -v 'sh ver'| grep -v System | awk '{print $2}' | tr '\n' '|';
 grep "image file" $logfile | awk -F [:] '{print $2}' | tr -d '/"' | tr '\n' '|';
 grep uptime $logfile | awk '{print $4$5,$6$7,$8$9,$10$11,$12$13}' | tr -d ',eksaourinut' | sed 's/dy /d /g'| tr '\n' '|';
 grep returned $logfile | awk '{print $6}' | tr '\n' '|';
 grep register $logfile | grep -v 'sh ver'| awk '{print $4}';
 echo "" > ${logfile} 
fi
done
#that's all folks

# EN syg5%6^7 
#username Netadmn9 privilege 15     
#ip domain-name HSBU
#crypto key generate rsa    #1024



#HSBU_1A(config)#line vty 0 4
#exec-timeout 5 0
#logging synchronous
#login local
#transport input telnet ssh
#transport output telnet ssh
#HSBU_1A(config-line)#end
#HSBU_2A(config)#crypto key generate rsa 