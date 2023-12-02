#!/usr/bin/bash

swayidle -w timeout 180 "$HOME/.config/sway/lock-screen.sh" \
            before-sleep "bash -c '$HOME/.config/sway/lock-screen.sh &'"
