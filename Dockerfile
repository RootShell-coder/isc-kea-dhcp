FROM debian:latest as builder

ARG KEA_DHCP_VERSION=2.2.0

RUN apt update && apt upgrade -y && apt install -y \
    git curl libboost-all-dev/stable openssl/stable libssl-dev build-essential autoconf dh-autoreconf \
    libssl-dev/stable liblog4cplus-dev/stable liblog4cplus-2.0.5/stable make cmake flex bison \
    libmysql++-dev/stable libpqxx-dev/stable postgresql-server-dev-all/stable \
    valgrind/stable && \
    curl -sL https://downloads.isc.org/isc/kea/${KEA_DHCP_VERSION}/kea-${KEA_DHCP_VERSION}.tar.gz | tar -zx -C /tmp

WORKDIR /tmp/kea-${KEA_DHCP_VERSION}

RUN autoreconf --verbose --force --install && \
   ./configure \
        --disable-static \
        --disable-dependency-tracking \
        --disable-silent-rules \
        --enable-generate-messages \
        --with-mysql \
        --prefix=/opt/kea \
        --with-log4cplus \
        --with-openssl \
        --with-boost-include \
        --disable-rpath && \
    make -s -j$(nproc) && \
    make install && \
    rm -rf /opt/kea/include

FROM debian:latest
LABEL maintainer "RootShell-coder <Root.Shelling@gmail.com>"

EXPOSE 67/udp
EXPOSE 8000/tcp

WORKDIR /opt/kea

COPY --from=builder /opt/kea/ /opt/kea/
COPY start-dhcp-server.sh /usr/local/bin

RUN apt update && apt install -y openssl liblog4cplus-2.0.5 valgrind libmariadb3 postgresql-client && \
    rm -rf /var/lib/apt/lists/* && \
    chmod +x /usr/local/bin/start-dhcp-server.sh

CMD ["start-dhcp-server.sh"]
