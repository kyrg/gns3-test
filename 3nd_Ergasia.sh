#!/bin/bash

ip=$(sudo ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9>
gw=$(ip r | grep "default" | awk '{ print $3}')
echo "your ip address: $ip and your gateway: $gw"

ip3=$(echo $ip | cut -d '.' -f1-2)
ip4=$(echo $ip | cut -d '.' -f3)
ip5=$((ip4-1))
ip2="$ip3"".""$ip5"
ip6="$ip3"".""$ip4"
gw2="$ip2"".1"
gw3="$ip6"".1"

mitroo=$(echo $ip | cut -d '.' -f1)
mitroo=$mitroo$(echo $ip | cut -d '.' -f2)
mitroo=$mitroo$(echo $ip | cut -d '.' -f3)
file="$mitroo""_askisi3.txt"
echo -e $mitroo'\t'$ip'\t'$gw  > $file

echo -n "Checking Mikrotik Router:   "
line=$(ssh -o StrictHostKeyChecking=accept-new -t admin@"$gw2" '/ip/dhcp-server>
echo "$line"
line=$(echo "$line" | sed $'s/\033[[][^A-Za-z]*m//g')
echo "$line" >> $file
#echo "$line"
server="$ip2"".0/24"
echo $server
echo $gw2

line2=$(echo "$line" | grep "$server" | grep "$gw2")
echo "$line2"

if [ "$line2" = "" ]; then
message="DHCP_SERVER_FAILED_1"
echo $message
echo $message>> $file

else
message="DHCP_SERVER_SUCCESS_1"
echo $message
echo $message>> $file
fi

exit
