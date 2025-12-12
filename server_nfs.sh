#!/bin/bash

WEB_ROUTE="/var/www/html"
NFS_CLIENTS="192.168.10.10,192.168.10.20"

# Instalar NFS + PHP-FPM
sudo apt update
sudo apt install -y nfs-kernel-server php8.1-fpm php8.1-mysql

# Eliminar NAT
sudo ip route del default

# Carpeta web NFS
sudo mkdir -p "$WEB_ROUTE"
sudo chown -R www-data:www-data "$WEB_ROUTE"
sudo chmod -R 755 "$WEB_ROUTE"

# Copiar archivos src
cd "$WEB_ROUTE"
sudo rm -f index.html
sudo cp -r /vagrant/src/* . 2>/dev/null || echo "No src folder"

# config.php 
DB_HOST="192.168.20.5"
DB_NAME="lamp_db"
DB_USER="user"
DB_PASS="pass"
CONFIG_FILE="$WEB_ROUTE/config.php"

if [ -f "$CONFIG_FILE" ]; then
    sudo sed -i "s/localhost/$DB_HOST/g" "$CONFIG_FILE"
    sudo sed -i "s/database_name_here/$DB_NAME/g" "$CONFIG_FILE"
    sudo sed -i "s/username_here/$DB_USER/g" "$CONFIG_FILE"
    sudo sed -i "s/password_here/$DB_PASS/g" "$CONFIG_FILE"
    echo "config.php configurado → HAProxy $DB_HOST"
fi

# Export NFS
echo "$WEB_ROUTE $NFS_CLIENTS(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -ra

# PHP-FPM TCP puerto 9000
sudo sed -i 's|listen = /run/php/php8.1-fpm.sock|listen = 0.0.0.0:9000|' /etc/php/8.1/fpm/pool.d/www.conf

# Arrancar
sudo systemctl restart nfs-kernel-server php8.1-fpm
sudo systemctl enable nfs-kernel-server php8.1-fpm

