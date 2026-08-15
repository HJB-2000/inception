#!/bin/bash
set -e

if [ -z "$MY_DOMAIN" ]; then
    echo "MY_DOMAIN is not set"
    exit 1
fi

mkdir -p /etc/nginx/ssl

openssl genrsa -out /etc/nginx/ssl/server.key 2048
openssl req -x509 \
    -key /etc/nginx/ssl/server.key \
    -out /etc/nginx/ssl/server.crt \
    -days 365 \
    -sha256 \
    -subj "/CN=$MY_DOMAIN" \
    -addext "subjectAltName=DNS:$MY_DOMAIN"

envsubst '${MY_DOMAIN}' \
    < /etc/nginx/nginx.conf.template \
    > /etc/nginx/nginx.conf

nginx -t || exit 1
exec nginx -g "daemon off;"