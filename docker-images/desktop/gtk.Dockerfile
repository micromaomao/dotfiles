FROM maowtm/archlinux-base-additions
RUN pacman -Syu --force --noconfirm && \
    pacman -S --force --noconfirm fontconfig libxtst gtk3 python cairo alsa-lib nss gcc-libs libnotify libxss glibc lsof # deps
COPY --chown=root:root ./makepkg.conf /etc/makepkg.conf
