#!/bin/bash
if [ "$1" = "" ]; then
	echo "Usage: ./request_dhcp ethX"
	exit 1
fi
link_status=`ethtool $1 | grep "Link detected" | awk -F ": " '{print $2}'`
if [ $link_status = "no" ]; then
	echo "Interface $1 is unplugged"
	exit 1
fi
ipaddr=`ifconfig $1 | grep "inet addr" | awk -F " " '{print $2}' | awk -F ":" '{print $2}'`
ipaddr_return=`echo $?`
if [ $ipaddr_return != 0 ]; then
	echo "Ifconfig problem or no IP Found"
	exit 1

fi
mask=`ifconfig $1 | grep "inet addr" | awk -F " " '{print $4}' | awk -F ":" '{print $2}'` 
cidr=`whatmask $ipaddr/$mask | grep CIDR | awk -F ": " '{print $2}'`
network=`whatmask $ipaddr/$mask | grep "Network Address" | awk -F ": " '{print $2}'`
nmap -sP $network$cidr | grep "Nmap scan report" > /tmp/discover.tmp
nmap_return=`echo $?`
iplist=`cat /tmp/discover.tmp | perl -nle '/(\d+\.\d+\.\d+\.\d+)/ && print "$1\n"' | grep -v "^$"`
echo "=IPLIST="
echo "$iplist"
exit 0
