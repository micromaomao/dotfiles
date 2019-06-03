FROM python:2

RUN pip install obfsproxy txsocksx
RUN apt-get update && apt-get install -y bind9-host

WORKDIR /
COPY ./entry.sh .
ENV SS_HOST=ss
ENV SS_PORT=1080
ENTRYPOINT ["./entry.sh"]
