#!/usr/bin/env bash

set -e

echo "Checking SSL certificate and private key..."

mkdir -p /etc/ssl/private /etc/ssl/certs

if [ ! -f /etc/ssl/private/nginx.key ] || [ ! -f /etc/ssl/certs/nginx.crt ]; then
    echo "Generating self-signed certificate..."

    openssl req -x509 -nodes -days 365 \
        -newkey rsa:4096 \
        -keyout /etc/ssl/private/nginx.key \
        -out /etc/ssl/certs/nginx.crt \
        -subj "/CN=jbahmida.42.fr"
fi

if [ ! -f /etc/ssl/private/nginx.key ] || [ ! -f /etc/ssl/certs/nginx.crt ]; then
    echo "Failed to create SSL certificate or private key."
    exit 1
fi

chmod 600 /etc/ssl/private/nginx.key
chmod 644 /etc/ssl/certs/nginx.crt

echo "SSL certificate is ready."

exec nginx -g "daemon off;"