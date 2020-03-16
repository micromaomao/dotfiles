FROM archlinux/base
WORKDIR /
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm v2ray && \
    rm -f /etc/v2ray/config.json

VOLUME [ "/etc/v2ray/config.json" ]
USER nobody:nobody
ENTRYPOINT [ "sh", "-c", "/usr/bin/v2ray -config /etc/v2ray/config.json" ]
