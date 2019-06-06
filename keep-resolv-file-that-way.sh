#!/usr/bin/bash

install -o 0 -g 0 -m 644 /home/mao/projects/dotfiles/etc/resolv.conf /etc/resolv.conf
while inotifywait -e modify -e delete -e delete_self /etc/resolv.conf; do
  install -o 0 -g 0 -m 644 /home/mao/projects/dotfiles/etc/resolv.conf /etc/resolv.conf
done
