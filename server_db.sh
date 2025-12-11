#!/bin/bash

# variables de entorno
DB_NAME="wordpress_db"
DB_USER="crisalm"
DB_PASS="pass"
DB_HOST="192.168.20.%"

set -e
sudo hostnamectl set-hostname DBCrisAlm

# Actualizar el sistema e instalar MariaDB.
sudo apt update
sudo apt install -y mariadb-server

# Configurando MySQL para escuchar en 0.0.0.0.
sudo sed -i "s/^bind-address.*127.0.0.1/bind-address = 0.0.0.0/g" /etc/mysql/mariadb.conf.d/50-server.cnf
sudo systemctl restart mariadb

# Creando la BD y usuario.
sudo mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARSET utf8mb4;
CREATE USER '$DB_USER'@'$DB_HOST' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'$DB_HOST' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
echo "Host: 192.168.20.50 | DB: $DB_NAME | User: $DB_USER | Pass: $DB_PASS"

# # Eliminar la puerta de enlace de la NAT
# sudo ip route del default