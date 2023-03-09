#!/bin/bash
ip=sudo ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'
echo $ip > test.txt
gw=ip r | grep "default" | awk '{ print $3}'
echo $gw >> test.txt
ping -c $gw >> test.txt

ping -c 5 8.8.8.8 >> test.txt
traceroute 8.8.8.8 >> test.txt
ls -la
exit
