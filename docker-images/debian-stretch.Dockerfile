FROM debian:stretch
RUN apt-get update && apt-get dist-upgrade && \
    apt-get install golang-go gcc g++
