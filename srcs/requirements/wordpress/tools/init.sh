#!/bin/bash

set -e

if     [ -f /run/secrets/db_password ] 
    && [ -f /run/secrets/wp_admin_password ] 
    && [ -f /run/secrets/wp_editor_password ]; then
    DB_PASSWORD="$(cat /run/secrets/db_password)"
    WP_ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_password)"
    WP_EDITOR_PASSWORD="$(cat /run/secrets/wp_editor_password)"
fi

until mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -e "SELECT 1" > /dev/null 2>&1; do
    sleep 2
done

cd /var/www/html

if [ ! -f wp-config.php ]; then
    wp core download --allow-root

    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost="${DB_HOST}" \
        --allow-root

    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --allow-root

    wp user create "${WP_EDITOR_USER}" "${WP_EDITOR_EMAIL}" \
        --role=editor \
        --user_pass="${WP_EDITOR_PASSWORD}" \
        --allow-root
fi

exec php-fpm8.2 -F