#!/bin/bash
intertube=0

ip=$(sudo ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
gw=$(ip r | grep "default" | awk '{ print $3}')
echo "your ip address: $ip and your gateway $gw"

echo -e $ip '\t' $gw  > test.txt

echo "begin ping to gateway"
while [ $intertube -ne 1 ]; do
        ping -c 5 $gw
        if [ $? -eq  0 ]; then
                echo "ping to gateway success";
                echo "ping to gateway  success" >> test.txt;
#                say success
                intertube=1;
        else
                echo "ping to gateway  failed"
                echo "ping to gateway  failed" >> test.txt


fi
done
intertube=0

echo "begin ping to 8.8.8.8"
while [ $intertube -ne 1 ]; do
        ping -c 5 8.8.8.8
        if [ $? -eq  0 ]; then
                echo "ping to 8.8.8.8 success";
                echo "ping to 8.8.8.8 success" >> test.txt;
#                say success
                intertube=1;
        else
                echo "ping to 8.8.8.8 failed"
                echo "ping to 8.8.8.8 failed" >> test.txt
        fi
done

echo "Start traceroute to 8.8.8.8"
line=$(traceroute -n 8.8.8.8 | tail -n 1)
hop=$(echo $line | awk '{ print $1 }') 
trace=$(echo $line | awk '{ print $2 }') 

if [ $trace == "8.8.8.8"  ]; then
echo "you reach 8.8.8.8 in $hop hops"
echo "traceroute SUCCESS " >> test.txt
else
echo "destiantion 8.8.8.8 not reach"
echo "traceroute FAILED" >> test.txt
fi



exit
