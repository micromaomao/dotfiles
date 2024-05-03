#!/bin/bash
FILE="/home/mao/Pictures/Screenshot from $(date '+%Y-%m-%d %H-%M-%S').png"
REGION="$(slurp)"
sleep 1
grim -t png -g "$REGION" "$FILE" && \
cat $FILE | wl-copy --type image/png
