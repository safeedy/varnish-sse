FROM ubuntu:latest

MAINTAINER Safidy Ambinintsoa <ambinintsoa.fs@gmail.com>

RUN apt-get update && apt-get install -y varnish varnish-modules curl

ADD start.sh /start.sh

RUN chmod +x /start.sh

ENV VCL_CONFIG      /etc/varnish/default.vcl
ENV CACHE_SIZE      64m
ENV VARNISHD_PARAMS -p default_ttl=3600 -p default_grace=3600

CMD /start.sh
EXPOSE 80