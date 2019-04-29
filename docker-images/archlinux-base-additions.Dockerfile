FROM archlinux/base
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm gcc make unzip grep p7zip bison pkgconf go
