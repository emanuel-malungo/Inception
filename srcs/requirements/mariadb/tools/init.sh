#!/bin/bash

MYSQL_USER="${MYSQL_USER}"
MYSQL_DATABASE="${MYSQL_DATABASE}"

if [ -f "/run/secrets/db_root_password.txt" ]; then
    DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password.txt)
fi

if [ -f "/run/secrets/db_password.txt" ]; then
    DB_PASSWORD=$(cat /run/secrets/db_password.txt)
fi

if [ ! -d "/var/lib/mysql/mysql" ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql
fi

mysqld_safe --datadir=/var/lib/mysql --skip-grant-tables --skip-networking &

sleep 5

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

mysqladmin -u root -p"${DB_ROOT_PASSWORD}" shutdown

echo "✅ MariaDB pronto!"
exec mysqld_safe --datadir=/var/lib/mysql
