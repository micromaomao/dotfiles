#!/usr/bin/env bash

state=$(powerprofilesctl get)
icon=""
next_state=""

case $state in
  "balanced")
      icon="."
      next_state="performance"
      ;;
  "performance")
      icon="P"
      next_state="power-saver"
      ;;
  "power-saver")
      icon="S"
      next_state="balanced"
      ;;
  *)
      icon="?"
      next_state="balanced"
      ;;
esac


if [ "$1" == "toggle" ]; then
  powerprofilesctl set $next_state
  pkill -SIGRTMIN+1 waybar
else
  echo -n '{"text": "'$icon'", "tooltip": "'$state'", "class": ["power_state", "ps_'$state'"]}'
fi
