#!/bin/bash

if [ -t 0 -a -t 1 -a -z "$TYPESCRIPT_REC" ]; then
  time=$(date +%Y%m%d_%H%M%S)
  export TYPESCRIPT_REC="$HOME/terminal-records/$time.typescript"
  export TYPESCRIPT_REC_TIMEFILE="$HOME/terminal-records/$time.typescript.tl"
  exec script -c $HOME/.terminalrc.sh -f -e -t$TYPESCRIPT_REC_TIMEFILE $TYPESCRIPT_REC
fi

if tmux has; then tmux a; else tmux; fi
