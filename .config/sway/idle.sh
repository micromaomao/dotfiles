#!/usr/bin/bash

swayidle -w timeout 180 "bash -c 'hyprlock & disown'" \
            before-sleep "bash -c '$HOME/.config/sway/lock-screen.sh &'"
