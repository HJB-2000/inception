FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    nodejs \
    tini \
    npm && \
    npm install -g http-server && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /site
COPY site/ .

EXPOSE 8081

CMD ["/usr/bin/tini", "--", "http-server", ".", "-p", "8081"]