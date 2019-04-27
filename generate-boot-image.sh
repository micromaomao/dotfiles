#!/bin/bash

bootimage=/boot/EFI/kernel.efi

objcopy \
  --add-section .osrel=/etc/os-release --change-section-vma .osrel=0x20000 \
  --add-section .cmdline=/proc/cmdline --change-section-vma .cmdline=0x30000 \
  --add-section .linux=/boot/vmlinuz-linux --change-section-vma .linux=0x40000 \
  --add-section .initrd=<(cat /boot/intel-ucode.img /boot/initramfs-linux.img) --change-section-vma .initrd=0x3000000 \
  /usr/lib/systemd/boot/efi/linuxx64.efi.stub $bootimage

/usr/bin/sbsign --key ~mao/efikeys/db.key --cert ~mao/efikeys/db.crt --output $bootimage $bootimage
