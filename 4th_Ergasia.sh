#!/bin/bash

ip=$(sudo ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
gw=$(ip r | grep "default" | awk '{ print $3}')
echo "your ip address: $ip and your gateway: $gw"

ip2=$(echo $ip | cut -d '.' -f1-3)
gw2="$ip2"".1"

mitroo=$(echo "${ip2//.}")
file="$mitroo""_askisi4.txt"
echo -e $mitroo'\t'$ip'\t'$gw  > $file

echo -n "Checking Gateway:  "

if [ $gw2 == $gw ]; then
                message="GW_CORRECT"
                echo $message
                echo $message >> $file
else
                message="GW_FAILED"
                echo $message
                echo $message >> $file

fi

(sleep 2; echo $mitroo; sleep 2; echo $mitroo; sleep 2; echo terminal length 0;echo show running-config; sleep 2) | telnet $gw  >> $file

echo -n "Submit result: y/n ?"
read -r line
        if [[ $line ==  "y" ]]; then
               message="entered yes. uploading results....good bye "
	       echo $message
	       curl -k -T $file -u "6NLwDpDMtJtXHQi:" -H 'X-Requested-With: XMLHttpRequest' \https://nextcloud.com.gr/modecsoft/public.php/webdav/$file
        else
                message="entered No. Good bye"
                echo $message
        fi

rm $file

exit
