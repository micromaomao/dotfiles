FROM busybox:musl
WORKDIR /
RUN cp /bin/busybox /busybox && \
    /busybox rm -rf /lib /lib64 /bin /sbin && \
    /busybox ln -sf /usr/lib lib && \
    /busybox ln -sf /usr/lib lib64 && \
    /busybox ln -sf /usr/bin bin && \
    /busybox ln -sf /usr/bin sbin && \
    /busybox adduser -s /usr/bin/fish -u 1000 -h /home/mao/ -D mao && \
    /busybox addgroup -g 1000 mao && \
    /busybox rm -rf /usr && \
    /busybox mkdir /usr && \
    /busybox mkdir -p /run/user/1000 && \
    /busybox chown 1000:1000 -R /run/user/1000

USER mao:mao
COPY --chown=1000:1000 .config /home/mao/.config
COPY --chown=1000:1000 .npmrc /home/mao/
COPY --chown=1000:1000 .vimrc /home/mao/
COPY --chown=0:0 .config /root/.config
COPY --chown=1000:1000 bare-entrypoint.sh /entrypoint.sh

ENV HOME=/home/mao/ SHELL=/usr/bin/fish XDG_RUNTIME_DIR=/run/user/1000

ENTRYPOINT [ "/usr/bin/fish" ]
