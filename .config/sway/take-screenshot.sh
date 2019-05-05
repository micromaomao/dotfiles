#!/bin/bash
FILE="/tmp/Screenshot-$(date +%Y%m%d_%H%M%S).png"
grim -t png "$FILE" && \
cat $FILE | wl-copy --type image/png
