FROM debian
RUN apt update && apt install -y curl && \
    echo downloading cloudflared && \
    cd /tmp && \
    curl -sfL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cfbin && \
    chmod +x cfbin && \
    useradd -m aaa && \
    chown aaa:aaa cfbin && \
    mv cfbin /home/aaa/
USER aaa
WORKDIR /home/aaa/
ENTRYPOINT [ "./cfbin", "--url" ]
