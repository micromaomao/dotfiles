#!/bin/bash
if ps -C hyprlock; then
  exit
fi

hyprlock & disown
