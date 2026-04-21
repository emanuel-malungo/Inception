#!/bin/bash

set -e

# ========================
# Secrets
# ========================
if [ -f /run/secrets/db_password ] && \
   [ -f /run/secrets/wp_admin_password ] && \
   [ -f /run/secrets/wp_editor_password ]; then

    DB_PASSWORD="$(cat /run/secrets/db_password)"
    WP_ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_password)"
    WP_EDITOR_PASSWORD="$(cat /run/secrets/wp_editor_password)"
fi

# ========================
# Esperar MariaDB
# ========================
echo "⏳ Esperando MariaDB..."

until mysql -h"$DB_HOST" -u"$MYSQL_USER" -p"$DB_PASSWORD" -e "SELECT 1" > /dev/null 2>&1; do
    sleep 2
done

cd /var/www/html

# ========================
# Baixar WordPress (se necessário)
# ========================
if [ ! -f wp-load.php ]; then
    echo "📥 Baixando WordPress..."
    wp core download --allow-root
fi

# ========================
# Configurar wp-config
# ========================
if [ ! -f wp-config.php ]; then
    echo "⚙️ Criando wp-config.php..."

    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost="${DB_HOST}" \
        --allow-root
fi

# ========================
# Instalar WordPress
# ========================
if ! wp core is-installed --allow-root; then
    echo "🚀 Instalando WordPress..."

    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    echo "👤 Criando usuário editor..."

    wp user create "${WP_EDITOR_USER}" "${WP_EDITOR_EMAIL}" \
        --role=editor \
        --user_pass="${WP_EDITOR_PASSWORD}" \
        --allow-root
fi

# ========================
# Permissões
# ========================
chown -R www-data:www-data /var/www/html

# ========================
# Start
# ========================
echo "✅ WordPress pronto!"
exec php-fpm8.2 -F