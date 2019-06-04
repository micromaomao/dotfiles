FROM archlinux/base
RUN pacman -Syu --noconfirm --force && \
    pacman -S --noconfirm --force awk bison curl file gcc git go grep make p7zip pkgconf rust which unzip
