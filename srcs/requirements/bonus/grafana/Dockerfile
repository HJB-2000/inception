FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive
ARG GRAFANA_VERSION=11.2.0
# deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    wget curl gnupg ca-certificates \
    tini \
    && rm -rf /var/lib/apt/lists/*
# grafana apt repo
RUN mkdir -p /etc/apt/keyrings \
    && wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor -o /etc/apt/keyrings/grafana.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" \
       > /etc/apt/sources.list.d/grafana.list
# install grafana
RUN apt-get update && apt-get install -y --no-install-recommends \
    grafana=${GRAFANA_VERSION} libfontconfig1 musl \
    && rm -rf /var/lib/apt/lists/*
# provisioning
COPY provisioning/ /etc/grafana/provisioning/

ENV GF_USERS_ALLOW_SIGN_UP=false \
    GF_PATHS_PROVISIONING=/etc/grafana/provisioning \
    GF_PATHS_DATA=/var/lib/grafana \
    GF_PATHS_LOGS=/var/log/grafana \
    GF_SECURITY_ADMIN_USER__FILE=/run/secrets/grafana_admin_user \
    GF_SECURITY_ADMIN_PASSWORD__FILE=/run/secrets/grafana_admin_password

RUN chown -R grafana:grafana /etc/grafana /var/lib/grafana /var/log/grafana
USER grafana
WORKDIR /usr/share/grafana
EXPOSE 3000
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/sbin/grafana-server", \
    "--homepath=/usr/share/grafana", \
    "--config=/etc/grafana/grafana.ini"]

    