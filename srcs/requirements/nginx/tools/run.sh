#!/bin/bash

set -e

if [ ! -f /etc/nginx/ssl/${DOMAIN_NAME}.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/${DOMAIN_NAME}.key \
        -out /etc/nginx/ssl/${DOMAIN_NAME}.crt \
        -subj "/C=BR/ST=State/L=City/O=Organization/CN=${DOMAIN_NAME}"
fi

ln -sf /etc/nginx/templates/nginx.conf.template /etc/nginx/sites-enabled/default 2>/dev/null || true

rm -f /var/run/nginx.pid

echo "✅ Nginx pronto!"
nginx -g "daemon off;"
