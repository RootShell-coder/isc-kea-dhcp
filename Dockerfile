FROM debian:latest as builder

ARG KEA_DHCP_VERSION=2.2.0

RUN apt update && apt upgrade -y && apt install -y \
    git curl libboost-all-dev/stable openssl/stable build-essential autoconf dh-autoreconf \
    libssl-dev/stable liblog4cplus-dev/stable liblog4cplus-2.0.5/stable make cmake \
    libmysql++-dev/stable libpqxx-dev/stable postgresql-server-dev-all/stable \
    valgrind/stable && \
    curl -sL https://downloads.isc.org/isc/kea/${KEA_DHCP_VERSION}/kea-${KEA_DHCP_VERSION}.tar.gz | tar -zx -C /tmp

WORKDIR /tmp/kea-${KEA_DHCP_VERSION}

RUN autoreconf --install && \
   ./configure --with-mysql --with-pgsql --prefix=/opt/kea && \
    make -s -j$(nproc) && \
    make install && \
    rm -rf /opt/kea/include


FROM debian:latest
LABEL maintainer "RootShell-coder <Root.Shelling@gmail.com>"

RUN apt update && apt install -y openssl liblog4cplus-2.0.5 valgrind
COPY --from=builder /opt/kea /opt/kea

EXPOSE 67/udp
EXPOSE 8080/tcp

WORKDIR /opt/kea

COPY start-dhcp-server.sh /usr/local/bin
RUN chmod +x /usr/local/bin/start-dhcp-server.sh
CMD ["start-dhcp-server.sh"]
