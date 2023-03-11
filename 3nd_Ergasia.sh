#!/bin/bash

ip=$(sudo ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
gw=$(ip r | grep "default" | awk '{ print $3}')
echo "your ip address: $ip and your gateway: $gw"

ip3=$(echo $ip | cut -d '.' -f1-2)
ip4=$(echo $ip | cut -d '.' -f3)
ip5=$((ip4-1))
ip2="$ip3"".""$ip5"
ip6="$ip3"".""$ip4"
echo $ip2
echo $ip6

mitroo=$(echo "${ip2//.}")
file="$mitroo"".txt"
echo -e $mitroo'\t'$ip'\t'$gw  > $file

echo -n "Checking Gateway:  "
gw2="$ip2"".1"
gw3="$ip6"".1"
#echo $gw2
if [ $gw2 == $gw ]; then
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

echo -n "Start traceroute to 8.8.8.8:  "
sudo traceroute -n -I 8.8.8.8 >> $file
line=$(traceroute -n 8.8.8.8 | tail -n 1)
hop=$(echo $line | awk '{ print $1 }') 
trace=$(echo $line | awk '{ print $2 }') 

if [ $trace == "8.8.8.8"  ]; then
echo "traceroute_SUCCESS: you reach 8.8.8.8 in $hop hops"
echo "traceroute_SUCCESS" >> $file
else
echo "traceroute_FAILED: destination 8.8.8.8 not reach"
echo "traceroute_FAILED" >> $file
fi

echo -n "Checking Mikrotik Router:   "
line=$(ssh -o StrictHostKeyChecking=accept-new -t admin@"$gw2" '/ip/dhcp-server/export; delay 1; quit;' | grep  "$gw2")
#echo $line
#line=$(echo $line | tee >(sed $'s/\033[[][^A-Za-z]*m//g'))
#echo $line
#echo $line >> $file
echo $line | tee >(sed $'s/\033[[][^A-Za-z]*m//g' >> $file)

#server="$ip2"".0/24"
#echo $server
line2=$(echo $line | grep "$server")
#echo $line2
if [ -z "$line2" ]; then
message="DHCP_SERVER_FAILED_1"
echo $message
echo $message>> $file
else
message="DHCP_SERVER_SUCCESS_1"
echo $message
echo $message>> $file
fi


gw3="$ip6"".1"
line=$(ssh -o StrictHostKeyChecking=accept-new -t admin@"$gw2" '/ip/dhcp-server/export; delay 1; quit;' | grep  "$gw3")
echo $line | tee >(sed $'s/\033[[][^A-Za-z]*m//g' >> $file)
line2=$(echo $line | grep "$server")

if [ -z "$line2" ]; then
message="DHCP_SERVER_FAILED_2"
echo $message
echo $message>> $file
else
message="DHCP_SERVER_SUCCESS_2"
echo $message
echo $message>> $file
fi



#ssh -o StrictHostKeyChecking=accept-new -t admin@"$gw2" '/ip/dhcp-server/export; delay 1; /ip/address/print; delay 1; /ip/route/print; delay 1; /ip/dhcp-client/print; delay 1; quit' | tee >(sed $'s/\033[[][^A-Za-z]*m//g' >> $file) 2>&1 
echo "continue"

curl -k -T $file -u "6NLwDpDMtJtXHQi:" -H 'X-Requested-With: XMLHttpRequest' \https://nextcloud.com.gr/modecsoft/public.php/webdav/$file

exit
