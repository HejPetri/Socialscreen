#!/bin/bash

gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.desktop.screensaver lock-enabled false

xdg-settings set default-web-browser google-chrome.desktop

(eog --fullscreen /opt/sg_kiosk/sg_logo.png) &

key=`cat /opt/sg_kiosk/data/key`

(unclutter -idle 0.1 -root) &

while true; do
  ping -c 1 www.google.com
  rc=$?
  if [ $rc -eq 0 ]; then
    sleep 3
    break
  fi
  sleep 3
done

while true; do
  vpn_ip=$(ifconfig tun0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
  LEN=$(echo ${#vpn_ip})
  if [ $LEN -gt 0 ]; then
    sleep 3
    break
  fi
  sleep 3
done

while true; do
  rm -rf ~/.cache/google-chrome/
  (sleep 3; kill -9 $(pgrep eog)) &
  google-chrome --kiosk --no-first-run --incognito "http://screen.socialgrab.me/router.php?key=$key"
done
