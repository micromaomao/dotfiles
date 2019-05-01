FROM archlinux/base
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm bison curl gcc git go grep make p7zip pkgconf rust unzip
