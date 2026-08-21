FROM debian:bookworm-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV GO_VERSION=1.22.2
ENV PATH=$PATH:/usr/local/go/bin

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    make \
    gcc \
    g++ \
    libc6-dev \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar -C /usr/local -xz

WORKDIR /go/src/github.com/google/cadvisor
RUN git clone --depth 1 https://github.com/google/cadvisor.git .
RUN GO_FLAGS="-tags=netgo" ./build/build.sh

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    dmsetup \
    thin-provisioning-tools \
    curl \
    tini \
    libc6 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /go/src/github.com/google/cadvisor/_output/cadvisor /usr/bin/cadvisor

EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/bin/cadvisor", "-logtostderr", "-port=8080"]