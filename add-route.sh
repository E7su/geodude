#!/bin/bash

GATEWAY=`route | grep rdhcp |  awk  '{print $2}'`

sudo route add default gw 127.0.0.1

sudo route add -net 127.0.0.1 netmask 255.255.0.0 gw $GATEWAY
