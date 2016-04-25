#!/bin/bash

sudo apt install -y network-manager
sudo nm-tools

echo "~~~~ wlan setup ~~~~"

read -p "Enter SSID: " SSID
read -p "Enter password: " PASS

sudo nmcli dev wifi con $SSID password $PASS
sudo ifconfig em1 down
