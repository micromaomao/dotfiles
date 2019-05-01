FROM debian:stretch
RUN apt-get update && apt-get -y dist-upgrade && \
    apt-get install -y curl g++ gcc git golang-go rustc
