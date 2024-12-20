ARG PG_VERSION

FROM bitnami/postgresql-repmgr:$PG_VERSION AS release

ARG TARGETARCH
ARG PG_VERSION
ARG PG_MAJOR_VERSION
ARG PGVECTORS_VERSION
ARG PGVECTOR_VERSION
ARG TSDB_VERSION

ENV POSTGRESQL_SHARED_PRELOAD_LIBRARIES="repmgr, pgaudit, timescaledb, vectors.so"

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


### pgvecto.rs
RUN set -ex; \
    apt-mark hold locales; \
    apt update; \
    apt install -y --no-install-recommends \
        unzip; \
    \
    mkdir /tmp/pgvectors; \
    if [ "${PG_MAJOR_VERSION}" = "17" ] && [ "${PGVECTORS_VERSION}" = "0.3.0" ]; then \
        # 下载 .deb 包并解压
        curl -fsSL https://github.com/tensorchord/pgvecto.rs/releases/download/v${PGVECTORS_VERSION}/vectors-pg${PG_MAJOR_VERSION}_${PGVECTORS_VERSION}_$(dpkg --print-architecture)_vectors.deb \
            -o /tmp/vectors.deb; \
        dpkg-deb -x /tmp/vectors.deb /tmp/pgvectors; \
        cp /tmp/pgvectors/usr/lib/postgresql/${PG_MAJOR_VERSION}/lib/vectors.so $(pg_config --pkglibdir); \
        cp /tmp/pgvectors/usr/share/postgresql/${PG_MAJOR_VERSION}/extension/vectors--* $(pg_config --sharedir)/extension; \
        cp /tmp/pgvectors/usr/share/postgresql/${PG_MAJOR_VERSION}/extension/vectors.control $(pg_config --sharedir)/extension; \
    else \
        curl -fsSL https://github.com/tensorchord/pgvecto.rs/releases/download/v${PGVECTORS_VERSION}/vectors-pg${PG_MAJOR_VERSION}_$(uname -m)-unknown-linux-gnu_${PGVECTORS_VERSION}.zip \
            -o /tmp/vectors.zip; \
        unzip /tmp/vectors.zip -d /tmp/pgvectors; \
        cp /tmp/pgvectors/vectors.so $(pg_config --pkglibdir); \
        cp /tmp/pgvectors/vectors--* $(pg_config --sharedir)/extension; \
        cp /tmp/pgvectors/vectors.control $(pg_config --sharedir)/extension; \
    fi; \
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
