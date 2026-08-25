FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        tini \
        php-cli \
        php8.2-mysql \
        wget \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN wget --tries=3 --timeout=15 -O adminer.php \
    https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php

EXPOSE 8082
CMD ["/usr/bin/tini", "--", "php", "-S", "0.0.0.0:8082", "-t", "/app"]