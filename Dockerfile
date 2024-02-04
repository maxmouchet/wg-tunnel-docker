FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install --no-install-recommends --yes \
    	curl \
	inetutils-ping \
	inetutils-traceroute \
        iproute2 \
        iptables \
        tini \
        wireguard-go \
        wireguard-tools \
    && rm -rf /var/lib/apt/lists/*

COPY main.sh /main.sh

ENTRYPOINT ["tini", "--"]
CMD ["/main.sh"]
