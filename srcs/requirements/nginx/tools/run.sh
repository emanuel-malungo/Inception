#!/bin/bash

set -e

mkdir -p /etc/nginx/ssl
if [ ! -f /etc/nginx/ssl/${DOMAIN_NAME}.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/${DOMAIN_NAME}.key \
        -out /etc/nginx/ssl/${DOMAIN_NAME}.crt \
        -subj "/C=BR/ST=State/L=City/O=Organization/CN=${DOMAIN_NAME}"
fi

envsubst '${DOMAIN_NAME}' < /etc/nginx/templates/nginx.conf.template > /etc/nginx/conf.d/default.conf

rm -f /var/run/nginx.pid

echo "✅ Nginx pronto!"
exec nginx -g "daemon off;"
