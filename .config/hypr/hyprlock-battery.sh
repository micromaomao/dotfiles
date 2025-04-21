#!/usr/bin/bash

battery_icons=(
    ""
    ""
    ""
    ""
    ""
)

charging_icon=""
plugged_icon=""

battery_current="$(cat /sys/class/power_supply/BAT0/capacity)"

battery_icon=""

if [ "$(cat /sys/class/power_supply/BAT0/status)" = "Charging" ]; then
    battery_icon="$charging_icon"
elif [ "$(cat /sys/class/power_supply/AC/online)" = "1" ]; then
    battery_icon="$plugged_icon"
elif [ $battery_current -le 20 ]; then
    battery_icon="${battery_icons[0]}"
elif [ $battery_current -le 40 ]; then
    battery_icon="${battery_icons[1]}"
elif [ $battery_current -le 60 ]; then
    battery_icon="${battery_icons[2]}"
elif [ $battery_current -le 80 ]; then
    battery_icon="${battery_icons[3]}"
else
    battery_icon="${battery_icons[4]}"
fi

echo "$battery_icon  $battery_current%"
