#!/bin/bash
#source https://github.com/x70b1/polybar-scripts
if [[ -f "/usr/bin/apt" ]]; then
  # apt is available
  updates=$(LANG=C apt-get upgrade -s |grep -P '^\d+ upgraded'|cut -d" " -f1)
else
  # arch variant
  if ! updates_arch=$(checkupdates 2> /dev/null | wc -l ); then
      updates_arch=0
  fi

  # if ! updates_aur=$(cower -u 2> /dev/null | wc -l); then
  if ! updates_aur=$(trizen -Su --aur --quiet | wc -l); then
      updates_aur=0
  fi

  updates=$(("$updates_arch" + "$updates_aur"))
fi

if [ "$updates" -gt 0 ]; then
    echo " $updates"
else
    echo "0"
fi
