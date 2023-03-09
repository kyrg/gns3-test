#!/bin/bash

ping -c 5 8.8.8.8 > test.txt
traceroute 8.8.8.8 > test.txt
ls -la
exit
