#!/bin/bash

if [ -t 0 -a -t 1 -a -z "$ITS_REC" ]; then
  time=$(date +%Y%m%d_%H%M%S)
  export ITS_REC="$HOME/terminal-records/$time.its"
  exec ts-player record $ITS_REC
fi

