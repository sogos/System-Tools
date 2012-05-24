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
#echo "Temporary stop networking on $1"
ifdown $1
ifdown_return=`echo $?`
if [ $ifdown_return != 0 ]; then
	echo "Ifdown problem"
	exit 1

fi
#echo "Requesting DHCP on $1"
dhclient $1
dhclient_return=`echo $?`
if [ $dhclient_return != 0 ]; then
	echo "DHclient problem"
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
#echo "Scanning Network Range"
nmap -sP $network$cidr | grep "Nmap scan report" > /tmp/discover.tmp
nmap_return=`echo $?`
iplist=`cat /tmp/discover.tmp | perl -nle '/(\d+\.\d+\.\d+\.\d+)/ && print "$1\n"' | grep -v "^$"`
#echo "Disabling DHCP process"
dhclient -r $1
dhclient_release_return=`echo $?`
#echo "Start normal networking"
ifup $1
ifup_return=`echo $?`
#echo $ifdown_return
#echo $ipaddr_return
#echo $dhclient_return
#echo $dhclient_release_return
#echo $ifup_return
echo "IPADDR = $ipaddr"
echo "CIDR = $cidr"
echo "NETWORK = $network"
echo "=IPLIST="
echo "$iplist"
exit 0
