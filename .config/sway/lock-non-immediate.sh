#!/bin/bash
if ps -C hyprlock; then
  exit
fi

hyprlock --grace 10 & disown
