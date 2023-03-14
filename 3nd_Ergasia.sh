#!/bin/bash

ip=$(sudo ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
gw=$(ip r | grep "default" | awk '{ print $3}')
echo "your ip address: $ip and your gateway: $gw"

ip3=$(echo $ip | cut -d '.' -f1-2)
ip4=$(echo $ip | cut -d '.' -f3)
ip5=$((ip4-1))
ip2="$ip3"".""$ip5"
ip6="$ip3"".""$ip4"
gw2="$ip2"".1"
gw3="$ip6"".1"

mitroo=$(echo "${ip2//.}")
file="$mitroo""_askisi3.txt"
echo -e $mitroo'\t'$ip'\t'$gw  > $file

echo -n "Checking Gateway:  "


if [ $gw3 == $gw ]; then
                message="GW_CORRECT"
                echo $message
                echo $message >> $file
else
                message="GW_FAILED"
                echo $message
                echo $message >> $file

fi

echo -n "begin ping to gateway 1:  "
line=""
line=$(ping -c 5  $gw2 | grep "received" | awk '{ print $4}')

        if [[ $line -eq  5 ]]; then
               message="ping to GW_SUCCESS_1"
                echo $message
                echo $message >> $file 
        else
                message="ping to GW_FAILED_1"
                echo $message
                echo $message >> $file  
        fi
echo -n "begin ping to gateway 2:  "
line=""
line=$(ping -c 5  $gw3 | grep "received" | awk '{ print $4}')

        if [[ $line -eq  5 ]]; then
               message="ping to GW_SUCCESS_2"
                echo $message
                echo $message >> $file 
        else
                message="ping to GW_FAILED_2"
                echo $message
                echo $message >> $file  
        fi

line=""	
#vpcs="$ip2"".""254"

echo -n "Enter VPCS IP address to ping (px 106.45.45.254): "
read -r line
vpcs=$line
echo -n "You entered: $vpcs   "

line=$(ping -c 5  "$vpcs" | grep "received" | awk '{ print $4}')
        if [[ $line -eq  5 ]]; then
               message="ping to VPCS_SUCCESS"
                echo $message
                echo $message >> $file 
        else
                message="ping to VPCS_FAIL"
                echo $message
                echo $message >> $file  
        fi


echo -n "begin ping to 8.8.8.8:  "
line=""
line=$(ping -c 5  8.8.8.8 | grep "received" | awk '{ print $4}')
        if [[ $line -eq  5 ]]; then
                message="ping to 8.8.8.8_SUCCESS"
                echo $message
		echo $message >> $file 
        else
                message="ping to 8.8.8.8_FAILED"
                echo $message
		echo $message >> $file 
        fi

line=""
echo -n "Start traceroute to 8.8.8.8 with ICMP:  "
line=$(sudo traceroute -n -I 8.8.8.8)
echo "$line" >> $file
r1=$(echo "$line" | head -3 | tail -1 | awk '{print $2}')
last_line=$(echo "$line" | tail -1)

#line=$(sudo traceroute -n -I 8.8.8.8 | tail -n 1)
hop=$(echo $last_line | awk '{ print $1 }') 
trace=$(echo $last_line | grep "8.8.8.8")
#echo $trace
if [[ $trace == ""  ]]; then
echo "traceroute_FAILED: destination 8.8.8.8 not reach"
echo "traceroute_FAILED" >> $file
else
echo "traceroute_SUCCESS: you reach 8.8.8.8 in $hop hops"
echo "traceroute_SUCCESS" >> $file
trace_success=true
fi

if [[ $trace_success != "true" ]];then
line=""
echo -n "Start traceroute to 8.8.8.8 with UDP:  "
line=$(sudo traceroute -n 8.8.8.8)
echo "$line" >> $file
last_line=$(echo "$line" | tail -1)
hop=$(echo $last_line | awk '{ print $1 }') 
trace=$(echo $last_line | grep "8.8.8.8")
#echo $trace

if [[ $trace == ""  ]]; then
echo "traceroute_FAILED: destination 8.8.8.8 not reach"
echo "traceroute_FAILED" >> $file
else
echo "traceroute_SUCCESS: you reach 8.8.8.8 in $hop hops"
echo "traceroute_SUCCESS" >> $file
fi
fi

echo -n "Checking Mikrotik Router:   "
line=$(ssh -o StrictHostKeyChecking=accept-new -t admin@"$gw2" '/ip/dhcp-server/export; delay 1; quit;' | grep  "gateway")
line=$(echo "$line" | sed $'s/\033[[][^A-Za-z]*m//g')
echo "$line" >> $file

server="$ip2"".0/24"
line2=$(echo "$line" | grep "$server" | grep "$gw2")
if [ -z "$line2" ]; then
message="DHCP_SERVER_FAILED_1"
echo $message
echo $message>> $file
else
message="DHCP_SERVER_SUCCESS_1"
echo $message
echo $message>> $file
fi


server="$ip6"".0/24"
line2=$(echo "$line" | grep "$server" | grep "$gw3")

if [ -z "$line2" ]; then
message="DHCP_SERVER_FAILED_2"
echo $message
echo $message>> $file
else
message="DHCP_SERVER_SUCCESS_2"
echo $message
echo $message>> $file
fi


line=""
echo -n "Submit result: y/n ?"
read -r line
        if [[ $line ==  "y" ]]; then
               message="entered yes. uploading results....good bye "
	       echo $message
	       curl -k -T $file -u "6NLwDpDMtJtXHQi:8eczBwSAcr" -H 'X-Requested-With: XMLHttpRequest' \https://nextcloud.com.gr/modecsoft/public.php/webdav/$file
        else
                message="entered No. Good bye"
                echo $message
        fi



exit
