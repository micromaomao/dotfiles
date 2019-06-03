FROM debian:jessie
WORKDIR /tmp
RUN apt-get update && \
    apt-get install -y wget && \
    wget 'http://delegate.hpcc.jp/anonftp/DeleGate/bin/linux/latest/linux2.6-dg9_9_13.tar.gz' && \
    tar zxf linux2.6-dg9_9_13.tar.gz && \
    rm linux2.6-dg9_9_13.tar.gz && \
    apt-get remove -y wget && \
    cd dg9_9_13/DGROOT/ && \
    install -D bin/dg9_9_13 /usr/bin/delegated && \
    install -D subin/* /usr/sbin/ && \
    cd ../.. && \
    rm -rf dg9_9_13

USER nobody:nobody
ENTRYPOINT ["delegated", "-f", "ADMIN=null@localhost"]
