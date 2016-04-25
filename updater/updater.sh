#!/bin/bash

function refresh_browser(){
  export DISPLAY=:0
  CHROME_WINDOW_ID=$(sudo xdotool search --onlyvisible --class chrome | head -1)
  sudo xdotool windowactivate $CHROME_WINDOW_ID
  sudo xdotool key 'CTRL+r'
  sudo bash -c 'last_refresh=$(date +%s); echo $last_refresh > /opt/sg_kiosk/data/last_refresh'
}

function check_status(){
  ps cax | grep chrome > /dev/null
  if [ $? -eq 0 ]; then
    status="STATUS_OK"
  else
    ps cax | grep eog > /dev/null
    if [ $? -eq 0 ]; then
      status="STATUS_BOOTING"
    else
      status="STATUS_FAILED"
    fi
  fi
  echo $status
}

function geo_location(){
  sudo bash -c 'curl "https://maps.googleapis.com/maps/api/browserlocation/json?browser=firefox&sensor=true&" --data-urlencode "`nmcli -f SSID,BSSID,SIGNAL dev wifi list |perl -ne "if(s/^(.+?)\s+(..:..:..:..:..:..)\s+(.+?)\s*$/&wifi=mac:\2|ssid:\1|ss:\3&/g){print;}"`" > /opt/sg_kiosk/data/geo_location'
}

function get_lat(){
  geo=`cat /opt/sg_kiosk/data/geo_location`
  lat=$(node -pe 'JSON.parse(process.argv[1]).location.lat' "$geo")
  echo $lat
}

function get_lng(){
  geo=`cat /opt/sg_kiosk/data/geo_location`
  lng=$(node -pe 'JSON.parse(process.argv[1]).location.lng' "$geo")
  echo $lng
}

function upgrade(){
  cd ~/Socialscreen
  make upgrade
}

function get_data(){
  TX_BYTES=$(ifconfig | grep 'bytes' | cut -d ':' -f 2 | cut -d ' ' -f 1)
  RX_BYTES=$(ifconfig | grep 'bytes' | cut -d ':' -f 3 | cut -d ' ' -f 1)
  
  tot=0

  array=( $(echo ${TX_BYTES//[a-z]/}) )
  for i in ${array[@]}; do
    let tot+=$i
  done

  array=( $(echo ${RX_BYTES//[a-z]/}) )
  for i in ${array[@]}; do
    let tot+=$i
  done

  echo $tot
}

sudo bash -c 'last_refresh=$(date +%s); echo $last_refresh > /opt/sg_kiosk/data/last_refresh'

sleep 10

while true; do
  ping -c 1 8.8.8.8
  rc=$?
  if [ $rc -eq 0 ]; then
    break
  fi
  sleep 3
done

geo_location

while true; do
  key=`cat /opt/sg_kiosk/data/key`
  last_refresh=`cat /opt/sg_kiosk/data/last_refresh`
  version=`cat /opt/sg_kiosk/data/VERSION`

  status=$(check_status)

  CPU=`top -b -n1 | grep "Cpu(s)" | awk '{print $2 + $4}'` 
  FREE_DATA=`free -m | grep Mem` 
  CURRENT=`echo $FREE_DATA | cut -f3 -d' '`
  TOTAL=`echo $FREE_DATA | cut -f2 -d' '`
  MEM=$(echo "scale = 2; $CURRENT/$TOTAL*100" | bc)
  HDD=`df -lh | awk '{if ($6 == "/") { print $5 }}' | head -1 | cut -d'%' -f1`

  uptimestr=`uptime -p`
  last_alive=$(date +%s)

  vpn_ip=$(ifconfig tun0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')

  data=$(get_data)

  lat=$(get_lat)
  lng=$(get_lng)

  json='{
      "status":"'"$status"'", 
      "key":"'"$key"'", 
      "cpu":"'"$CPU"'", 
      "mem":"'"$MEM"'", 
      "hdd":"'"$HDD"'",
      "uptime":"'"$uptimestr"'",
      "last_refresh":"'"$last_refresh"'",
      "last_alive":"'"$last_alive"'",
      "version":"'"$version"'",
      "vpn_ip":"'"$vpn_ip"'",
      "data":"'"$data"'",
      "lat":"'"$lat"'",
      "lng":"'"$lng"'"
    }'

  res=$(curl -s \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$json" "http://46.101.117.243/ping.php")

  status=$(node -pe 'JSON.parse(process.argv[1]).status' "$res")
  audio=$(node -pe 'JSON.parse(process.argv[1]).audio' "$res")

  case "$status" in
    'STATUS_OK')
    ;;

    'STATUS_REBOOT')
    sudo reboot
    ;;

    'STATUS_SHUTDOWN')
    sudo shutdown -h now
    ;;

    'STATUS_RELOAD')
    refresh_browser
    ;;

    'STATUS_UPGRADE')
    upgrade
    ;;
  esac

  case "$audio" in
    '0')
    sudo su -c "amixer -D pulse set Master 1+ mute" -s /bin/sh socialgrab
    ;;

    '1')
    sudo su -c "amixer -D pulse set Master 1+ unmute" -s /bin/sh socialgrab
    ;;
  esac

  sleep 1
done
