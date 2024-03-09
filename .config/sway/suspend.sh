#!/bin/bash
hyprlock --immediate & disown
sleep 2
sudo systemctl suspend
