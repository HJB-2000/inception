#!/bin/bash

set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/credentials | sed -n '1p')
WP_USER_PASSWORD=$(cat /run/secrets/credentials | sed -n '2p')

echo "Waiting for MariaDB..."
until mysqladmin ping -h mariadb -u"$MYSQL_USER" -p"$DB_PASSWORD" --silent; do
    sleep 2
done
echo "MariaDB is up."
echo "Waiting for Redis..."
until redis-cli -h redis ping 2>/dev/null | grep -q PONG; do
    sleep 1
done
echo "Redis is up."




if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Installing WordPress..."
    wp core download --allow-root
    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$DB_PASSWORD" \
        --dbhost=mariadb \
        --allow-root
    wp core install \
        --url="https://$DOMAIN_NAME" \
        --title="Inception" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --allow-root
    wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --role=author \
        --user_pass="$WP_USER_PASSWORD" \
        --allow-root
    echo "WordPress installed."
else
    echo "WordPress already installed, skipping core setup."
fi

echo "Ensuring Redis cache is configured..."
if ! wp plugin is-installed redis-cache --allow-root; then
    wp plugin install redis-cache --activate --allow-root
else
    wp plugin activate redis-cache --allow-root || true
fi
wp config get WP_REDIS_HOST --allow-root >/dev/null 2>&1 || wp config set WP_REDIS_HOST redis --allow-root
wp config get WP_REDIS_PORT --allow-root >/dev/null 2>&1 || wp config set WP_REDIS_PORT 6379 --raw --allow-root
wp config get WP_CACHE --allow-root >/dev/null 2>&1 || wp config set WP_CACHE true --raw --allow-root
if ! wp redis status --allow-root | grep -q "Status: Connected"; then
    wp redis enable --allow-root || true
fi
chown -R www-data:www-data /var/www/html
exec php-fpm8.2 -F