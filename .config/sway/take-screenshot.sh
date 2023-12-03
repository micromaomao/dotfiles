#!/bin/bash
FILE="/home/mao/Pictures/Screenshot from $(date '+%Y-%m-%d %H-%M-%S').png"
grim -t png "$FILE" && \
cat $FILE | wl-copy --type image/png
