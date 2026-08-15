FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    openssl \
    gettext-base \
    tini \
    && rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/nginx.conf.template
COPY tools/nginx_int.sh /nginx_int.sh

RUN chmod +x /nginx_int.sh && \
    sed -i 's/\r$//' /nginx_int.sh

EXPOSE 443

ENTRYPOINT ["/usr/bin/tini", "--", "/nginx_int.sh"]