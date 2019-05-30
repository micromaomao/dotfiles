FROM archlinux/base
RUN pacman -Syu --noconfirm --force && \
    pacman -S --noconfirm --force bison curl gcc git go grep make p7zip pkgconf rust unzip
