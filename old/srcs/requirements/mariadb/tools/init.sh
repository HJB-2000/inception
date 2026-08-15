#!/usr/bin/env bash

set -e

: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD is required}"

DATADIR="/var/lib/mysql"
SOCKET="/run/mysqld/mysqld.sock"

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

mkdir -p "${DATADIR}"
chown -R mysql:mysql "${DATADIR}"

if [ ! -d "${DATADIR}/mysql" ]; then
    echo "Initializing MariaDB..."

    mariadb-install-db \
        --user=mysql \
        --datadir="${DATADIR}"

    echo "Starting temporary MariaDB..."

    mariadbd \
        --user=mysql \
        --datadir="${DATADIR}" \
        --socket="${SOCKET}" \
        --skip-networking &

    pid=$!

    echo "Waiting for MariaDB..."

    until mariadb-admin \
        --socket="${SOCKET}" \
        ping \
        --silent
    do
        sleep 1
    done

    mariadb --socket="${SOCKET}" <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
EOF

    echo "Stopping temporary MariaDB..."

    mariadb-admin \
        --socket="${SOCKET}" \
        shutdown

    wait "${pid}"
fi

echo "Starting MariaDB..."

exec mariadbd \
    --user=mysql \
    --datadir="${DATADIR}" \
    --socket="${SOCKET}"