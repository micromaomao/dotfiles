#!/bin/bash
set -e

function fix () {
dconf reset -f /org/gnome/desktop/wm/keybindings/
dconf load /org/gnome/desktop/wm/keybindings/ <<EOF
[/]
close=['<Shift><Super>q']
cycle-windows=['<Alt>Tab']
cycle-windows-backward=['<Shift><Alt>Tab']
move-to-workspace-1=['<Shift><Super>exclam']
move-to-workspace-2=['<Shift><Super>at']
move-to-workspace-3=['<Shift><Super>numbersign']
move-to-workspace-4=['<Shift><Super>dollar']
switch-applications=@as []
switch-applications-backward=@as []
switch-to-workspace-1=['<Super>1']
switch-to-workspace-2=['<Super>2']
switch-to-workspace-3=['<Super>3']
switch-to-workspace-4=['<Super>4']
switch-windows=@as []
switch-windows-backward=@as []
EOF
}

while :; do
fix
echo fixed
sleep 5
done
