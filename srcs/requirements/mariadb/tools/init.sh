#!/bin/bash

set -e

MYSQL_USER="${MYSQL_USER}"
MYSQL_DATABASE="${MYSQL_DATABASE}"

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

if [ -f "/run/secrets/db_root_password" ]; then
    DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
fi

if [ -f "/run/secrets/db_password" ]; then
    DB_PASSWORD=$(cat /run/secrets/db_password)
fi

if [ ! -d "/var/lib/mysql/mysql" ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql
fi

# Inicialização temporária: sem rede, sem grant tables, em background
mysqld --user=mysql --skip-networking --skip-grant-tables &
MYSQL_PID=$!

# Aguarda o socket ficar disponível (sem sleep fixo)
until mysqladmin ping --silent 2>/dev/null; do
    sleep 1
done

mysql -u root <<EOF
    FLUSH PRIVILEGES;
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
    DELETE FROM mysql.user WHERE User='';
    CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
    DROP DATABASE IF EXISTS test;
    CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
    FLUSH PRIVILEGES;
EOF

# Encerra o mysqld temporário de forma limpa e aguarda
kill $MYSQL_PID
wait $MYSQL_PID

echo "✅ MariaDB pronto!"
# mysqld vira PID 1 com exec — sem wrapper, sem background
exec mysqld --user=mysql --datadir=/var/lib/mysql