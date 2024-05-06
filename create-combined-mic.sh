#!/usr/bin/bash

v="$(pactl list modules | grep -B 2 'sink_name=combined-mic' | head -n1)"
if [ ! -z "$v" ]; then
  echo Removing combined-mic
  pactl unload-module ${v#Module \#}
  exit 0
fi

pactl load-module module-null-sink media.class=Audio/Source/Virtual node.passive=true node.latency=8192/48000 sink_name=combined-mic channel_map=front-left,front-right
sleep 0.5

for SIDE in FL FR; do
  # Dock output
  pw-link alsa_output.usb-DisplayLink_ThinkPad_Hybrid_USB-C_with_USB-A_Dock_21272393-02.analog-stereo:monitor_$SIDE combined-mic:input_$SIDE
  # Laptop output
  pw-link alsa_output.pci-0000_05_00.6.analog-stereo:monitor_$SIDE combined-mic:input_$SIDE
  # Dock mic input
  pw-link alsa_input.usb-DisplayLink_ThinkPad_Hybrid_USB-C_with_USB-A_Dock_21272393-02.analog-stereo:capture_$SIDE combined-mic:input_$SIDE
done
