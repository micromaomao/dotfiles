FROM archlinux/base
WORKDIR /
RUN pacman -Syu --force --noconfirm && \
    pacman -S --force --noconfirm v2ray && \
    rm -f /etc/v2ray/config.json

VOLUME [ "/etc/v2ray/config.json" ]
USER nobody:nobody
ENTRYPOINT [ "sh", "-c", "V2RAY_LOCATION_ASSET=/etc/v2ray /usr/bin/v2ray -config /etc/v2ray/config.json" ]
