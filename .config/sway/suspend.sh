#!/bin/bash
BACKLIGHT="$(xbacklight phy0-led -get)"
FILE="/tmp/Screenshot-$(date +%Y%m%d_%H%M%S).png"
grim -t png "$FILE" && \
LOCKIMAGE="$(mktemp /tmp/lock-XXXXXXXXXXX.png)"
convert "$FILE" -virtual-pixel transparent -background white -filter Gaussian -resize 20% -define "filter:sigma=2" \
  -resize 500.5% -fill 'rgba(255,255,255,0.5)' -draw 'rectangle 0,0 10000,10000' "$LOCKIMAGE"
swaylock --daemonize -i "$LOCKIMAGE"
sleep 2
sudo systemctl suspend
