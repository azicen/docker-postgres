ARG PG_VERSION

FROM bitnami/postgresql-repmgr:$PG_VERSION AS release

ARG TARGETARCH
ARG PG_VERSION
ARG PG_MAJOR_VERSION
ARG PGVECTORS_VERSION
ARG PGVECTOR_VERSION
ARG TSDB_VERSION

USER root

RUN set -ex; \
    apt-mark hold locales; \
    apt update; \
    apt install -y --no-install-recommends \
        curl; \
    apt-mark unhold locales; \
    apt autoremove -y; \
    apt autoclean -y; \
    apt clean; \
    rm -rf \
        /config/.cache \
        /config/.launchpadlib \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /tmp/*


### pgvector
RUN set -ex; \
    apt-mark hold locales; \
    apt update; \
    apt install -y --no-install-recommends \
        git \
        build-essential \
        postgresql-server-dev-${PG_MAJOR_VERSION}; \
    \
    git clone --branch v${PGVECTOR_VERSION} \
        https://github.com/pgvector/pgvector.git /tmp/pgvector; \
    cd /tmp/pgvector; \
    make; \
    make install; \
    \
    mkdir /usr/share/doc/pgvector; \
	cp LICENSE README.md /usr/share/doc/pgvector; \
    \
	apt remove -y --no-install-recommends \
        git \
        build-essential \
        postgresql-server-dev-${PG_MAJOR_VERSION}; \
    apt-mark unhold locales; \
    apt autoremove -y; \
    apt autoclean -y; \
    apt clean; \
    rm -rf \
        /config/.cache \
        /config/.launchpadlib \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /tmp/*


### pgvecto.rs
RUN set -ex; \
    curl -fsSL https://github.com/tensorchord/pgvecto.rs/releases/download/v${PGVECTORS_VERSION}/vectors-pg${PG_MAJOR_VERSION}_$(uname -m)-unknown-linux-gnu_${PGVECTORS_VERSION}.zip \
        -o /tmp/vectors.zip; \
    apt-mark hold locales; \
    apt update; \
    apt install -y --no-install-recommends \
        unzip; \
    \
    mkdir /tmp/pgvectors; \
    unzip /tmp/vectors.zip -d /tmp/pgvectors; \
    cp /tmp/pgvectors/vectors.so $(pg_config --pkglibdir); \
    cp /tmp/pgvectors/vectors--* $(pg_config --sharedir)/extension; \
    cp /tmp/pgvectors/vectors.control $(pg_config --sharedir)/extension; \
    \
    mkdir /usr/share/doc/pgvectors; \
    curl -fsSL https://raw.githubusercontent.com/tensorchord/pgvecto.rs/refs/tags/v${PGVECTORS_VERSION}/README.md \
        -o /usr/share/doc/pgvectors/README.md; \
    curl -fsSL https://raw.githubusercontent.com/tensorchord/pgvecto.rs/refs/tags/v${PGVECTORS_VERSION}/LICENSE \
        -o /usr/share/doc/pgvectors/LICENSE; \
    \
    apt remove -y --no-install-recommends \
        unzip; \
    apt-mark unhold locales; \
    apt autoremove -y; \
    apt autoclean -y; \
    apt clean; \
    rm -rf \
        /config/.cache \
        /config/.launchpadlib \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /tmp/*


### timescaledb
RUN set -ex; \
    apt-mark hold locales; \
    apt update; \
    apt install -y --no-install-recommends \
        git \
        cmake \
        libssl-dev; \
    \
    git clone --branch ${TSDB_VERSION} \
        https://github.com/timescale/timescaledb.git /tmp/timescaledb; \
    cd /tmp/timescaledb; \
    ./bootstrap \
    cd build && make; \
    make install; \
    \
    mkdir /usr/share/doc/timescaledb; \
    cd ..; \
    cp LICENSE LICENSE-APACHE README.md /usr/share/doc/timescaledb; \
    \
    apt remove -y --no-install-recommends \
        git \
        cmake \
        libssl-dev; \
    apt-mark unhold locales; \
    apt autoremove -y; \
    apt autoclean -y; \
    apt clean; \
    rm -rf \
        /config/.cache \
        /config/.launchpadlib \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /tmp/*


USER 1001
