FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y redis-server tini

COPY conf/redis.conf /etc/redis/redis.conf

RUN mkdir -p /var/lib/redis && chown redis:redis /var/lib/redis

EXPOSE 6379

ENTRYPOINT ["tini", "--", "redis-server", "/etc/redis/redis.conf"]
