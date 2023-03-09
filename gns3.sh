#!/bin/bash

ip=$(sudo ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
gw=$(ip r | grep "default" | awk '{ print $3}')
echo "your ip address: $ip and your gateway: $gw"

file=$(echo "${ip//.}").txt

echo -e $ip '\t' $gw  > $file

echo "begin ping to gateway"
intertube=0
while [ $intertube -ne 1 ]; do
        #ping -c 5 $gw        
        line=$(ping -c 5 $gw  | tail -n 1)
        if [ $? -eq  0 ]; then
                echo "ping to gateway success";
                echo "ping GATEWAY SUCCESS" >> $file
                intertube=1;
        else
                echo "ping to gateway  failed"
                echo "ping GATEWAY FAILED" >> $file


fi
done
intertube=0

echo "begin ping to 8.8.8.8"
while [ $intertube -ne 1 ]; do
        line=$(ping -c 5  8.8.8.8  | tail -n 1)
       # ping -c 5 8.8.8.8
        if [ $? -eq  0 ]; then
                echo "ping to 8.8.8.8 success";
                echo "ping GOOGLE SUCCESS" >> $file
#                say success
                intertube=1;
        else
                echo "ping to 8.8.8.8 failed"
                echo "ping GOOGLE FAILED" >> $file
        fi
done

echo "Start traceroute to 8.8.8.8"
line=$(traceroute -n 8.8.8.8 | tail -n 1)
hop=$(echo $line | awk '{ print $1 }') 
trace=$(echo $line | awk '{ print $2 }') 

if [ $trace == "8.8.8.8"  ]; then
echo "you reach 8.8.8.8 in $hop hops"
echo "traceroute SUCCESS " >> $file
else
echo "destiantion 8.8.8.8 not reach"
echo "traceroute FAILED" >> $file
fi

echo "Checking Mikrotik Router"
ssh -o StrictHostKeyChecking=accept-new -t admin@107.11.13.1 '/ip/dhcp-server/export; delay 1; /ip/address/print; delay 1; /ip/route/print; delay 1; /ip/dhcp-client/print; delay 1; quit' | tee >(sed $'s/\033[[][^A-Za-z]*m//g' >> $file)

curl -k -T $file -u "6NLwDpDMtJtXHQi:" -H 'X-Requested-With: XMLHttpRequest' \https://nextcloud.com.gr/modecsoft/public.php/webdav/$file

exit
