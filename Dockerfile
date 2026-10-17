FROM rust:slim-trixie@sha256:4df2ae8cfdfebdfc13a65da7f253b73d68983dc0339f2719bc17a279c913b13d AS builder

ENV PROTOC_VERSION=36.1

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    git=1:2.47.* \
    clang=1:19.* \
    libclang-dev=1:19.* \
    pkg-config=1.8.1-* \
    curl=8.14.* \
    unzip=6.0-* \
    libmnl-dev=1.0.* \
    libnftables-dev=1.* \
    && ARCH=$(uname -m) \
    && PROTOC_ARCH="${ARCH/aarch64/aarch_64}" \
    && curl -sSL "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-${PROTOC_ARCH}.zip" -o protoc.zip \
    && unzip protoc.zip -d /usr/local \
    && rm protoc.zip \
    && rustup component add rustfmt \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN git clone --recurse-submodules https://github.com/sorz/dnsnfset.git . && \
    cargo build --release


FROM debian:trixie-slim@sha256:62bd423aeee912639ca8ee681c2b762cb3e25137e0a92b20be455898a9f034ad

RUN apt-get update && apt-get install -y --no-install-recommends \
    libnftables1=1.1.3-1 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder \
    /build/target/release/dnsnfset \
    /usr/local/bin/dnsnfset

COPY --from=builder /build/rules.toml /etc/dnsnfset/rules.toml

ENTRYPOINT ["/usr/local/bin/dnsnfset"]