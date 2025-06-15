ARG PG_VERSION

FROM bitnami/postgresql-repmgr:$PG_VERSION AS release

ARG TARGETARCH
ARG PG_VERSION
ARG PG_MAJOR_VERSION
ARG PGVECTORS_VERSION
ARG PGVECTOR_VERSION
ARG TSDB_VERSION

ENV POSTGRESQL_SHARED_PRELOAD_LIBRARIES="repmgr, pgaudit, timescaledb, vectors.so, pg_stat_statements"

USER root

RUN set -ex; \
    ldd /bin/bash;

RUN set -ex; \
    apt-mark hold locales; \
    apt update; \
    apt install -y --no-install-recommends \
        curl \
        ca-certificates \
        iproute2 \
        iputils-ping \
        less \
        procps; \
    apt-mark unhold locales; \
    apt autoremove -y; \
    apt autoclean -y; \
    apt clean; \
    rm -rf \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /tmp/*


### pgvector
RUN set -ex; \
    apt-mark hold locales; \
    apt update; \
    apt install -y --no-install-recommends \
        build-essential \
        git; \
    \
    git clone --branch v${PGVECTOR_VERSION} \
        https://github.com/pgvector/pgvector.git /tmp/pgvector; \
    cd /tmp/pgvector; \
    make OPTFLAGS=""; \
    make install; \
    \
    mkdir /usr/share/doc/pgvector; \
	cp LICENSE README.md /usr/share/doc/pgvector; \
    \
	apt remove -y --no-install-recommends \
        build-essential \
        git; \
    apt-mark unhold locales; \
    apt autoremove -y; \
    apt autoclean -y; \
    apt clean; \
    rm -rf \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /tmp/*


### timescaledb
RUN set -ex; \
    apt-mark hold locales; \
    apt update; \
    apt install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        libssl-dev; \
    \
    git clone --branch ${TSDB_VERSION} \
        https://github.com/timescale/timescaledb.git /tmp/timescaledb; \
    cd /tmp/timescaledb; \
    ./bootstrap; \
    cd build; \
    make; \
    make install; \
    \
    mkdir /usr/share/doc/timescaledb; \
    cd ..; \
    cp LICENSE LICENSE-APACHE README.md /usr/share/doc/timescaledb; \
    \
    apt remove -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        libssl-dev; \
    apt-mark unhold locales; \
    apt autoremove -y; \
    apt autoclean -y; \
    apt clean; \
    rm -rf \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /tmp/*


USER 1001
