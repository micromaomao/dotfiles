FROM busybox:musl
WORKDIR /
RUN cp /bin/busybox /busybox && \
    /busybox rm -rf /lib /lib64 /bin /sbin && \
    /busybox ln -sf /usr/lib lib && \
    /busybox ln -sf /usr/lib lib64 && \
    /busybox ln -sf /usr/bin bin && \
    /busybox ln -sf /usr/bin sbin && \
    /busybox adduser -s /usr/bin/fish -u 1000 -h /home/mao/ -D mao && \
    /busybox rm -rf /usr && \
    /busybox mkdir /usr

USER mao:mao
# This image should be run with /usr mounted to some read-only host /usr.
# Like: docker run -it -u 1000:1000 -v /tmp/.X11-unix/:/tmp/.X11-unix:ro -e DISPLAY=:0 -v /usr/:/usr/:ro -v /opt/:/opt/:ro --entrypoint /busybox maowtm/bare sh
VOLUME [ "/usr", "/opt", "/tmp/.X11-unix" ]

COPY --chown=1000:1000 .config /home/mao/.config
COPY --chown=1000:1000 .npmrc /home/mao/
COPY --chown=1000:1000 .vimrc /home/mao/
VOLUME [ "/home/mao/.fonts" ]

ENV HOME=/home/mao/ SHELL=/usr/bin/fish

ENTRYPOINT [ "/usr/bin/fish" ]