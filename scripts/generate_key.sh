#!/bin/bash

key=$(cat /proc/sys/kernel/random/uuid)
IFS=-
set $key
key=$1

if [ ! -f /opt/sg_kiosk/data/key ]; then
  echo $key > /opt/sg_kiosk/data/key
  echo "Key generated: $key"
fi
