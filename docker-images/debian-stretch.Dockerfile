FROM debian:stretch
RUN apt-get update && apt-get -y dist-upgrade && \
    apt-get install -y golang-go gcc g++ rustc
