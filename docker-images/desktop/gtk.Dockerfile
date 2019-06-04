FROM archlinux/base
RUN pacman -Syu --noconfirm --force && \
    pacman -S --noconfirm --force alsa-lib awk bison cairo curl file fontconfig gcc gcc-libs git glibc go grep gtk3 libnotify libxss libxtst lsof make nss p7zip pkgconf python rust unzip which
COPY --chown=root:root ./makepkg.conf /etc/makepkg.conf
