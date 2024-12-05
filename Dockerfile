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
        curl \
        postgresql-common; \
    /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y; \
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
    mkdir /tmp/pgvectors; \
    curl -fsSL https://github.com/tensorchord/pgvecto.rs/releases/download/v${PGVECTORS_VERSION}/vectors-pg${PG_MAJOR_VERSION}_${PGVECTORS_VERSION}_${TARGETARCH}.deb \
        -o /tmp/pgvectors/vectors.deb; \
    apt-mark hold locales; \
    apt update; \
    apt --fix-broken install -y --no-install-recommends \
        /tmp/pgvectors/vectors.deb; \
    \
    mkdir /usr/share/doc/pgvectors; \
    curl -fsSL https://raw.githubusercontent.com/tensorchord/pgvecto.rs/refs/tags/v${PGVECTORS_VERSION}/README.md \
        -o /usr/share/doc/pgvectors/README.md; \
    curl -fsSL https://raw.githubusercontent.com/tensorchord/pgvecto.rs/refs/tags/v${PGVECTORS_VERSION}/LICENSE \
        -o /usr/share/doc/pgvectors/LICENSE; \
    \
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
    echo "deb https://packagecloud.io/timescale/timescaledb/debian/ $(lsb_release -c -s) main" \
        | sudo tee /etc/apt/sources.list.d/timescaledb.list; \
    curl -fsSL https://packagecloud.io/timescale/timescaledb/gpgkey \
        | gpg --dearmor -o /etc/apt/trusted.gpg.d/timescaledb.gpg; \
    apt-mark hold locales; \
    apt update; \
    apt install -y --no-install-recommends \
        timescaledb-2-postgresql-${PG_MAJOR_VERSION}='${TSDB_VERSION}*' \
        timescaledb-2-loader-postgresql-${PG_MAJOR_VERSION}='${TSDB_VERSION}*'; \
    \
    mkdir /usr/share/doc/timescaledb; \
    curl -fsSL https://raw.githubusercontent.com/timescale/timescaledb/refs/tags/${TSDB_VERSION}/README.md \
        -o /usr/share/doc/timescaledb/README.md; \
    curl -fsSL https://raw.githubusercontent.com/timescale/timescaledb/refs/tags/${TSDB_VERSION}/LICENSE \
        -o /usr/share/doc/timescaledb/LICENSE; \
    curl -fsSL https://raw.githubusercontent.com/timescale/timescaledb/refs/tags/${TSDB_VERSION}/LICENSE-APACHE \
        -o /usr/share/doc/timescaledb/LICENSE-APACHE; \
    \
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
