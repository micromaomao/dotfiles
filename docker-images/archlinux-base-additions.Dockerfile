FROM archlinux/base
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm awk bison curl file gcc git go grep make p7zip pkgconf rust which unzip
