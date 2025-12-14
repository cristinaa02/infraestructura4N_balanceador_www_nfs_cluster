#!/bin/bash

WEB_ROUTE="/var/www/html"
NFS_CLIENT1="192.168.20.10"
NFS_CLIENT2="192.168.20.20"

# Instalar NFS + PHP-FPM
sudo apt update
sudo apt install -y nfs-kernel-server php-fpm php-mysql php-cli php-curl php-gd php-mbstring php-xml php-zip

# Carpeta web NFS
sudo mkdir -p "$WEB_ROUTE"
sudo chown -R www-data:www-data "$WEB_ROUTE"
sudo chmod -R 755 "$WEB_ROUTE"

# Copiar archivos src
cd "$WEB_ROUTE"
sudo rm -f index.html
sudo cp -r /vagrant/src/* . || echo "No src folder"

PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
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
echo "$WEB_ROUTE $NFS_CLIENT1(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
echo "$WEB_ROUTE $NFS_CLIENT2(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -a

# PHP-FPM TCP puerto 9000
sudo sed -i 's|listen = /run/php/php*-fpm.sock|listen = 0.0.0.0:9000|' /etc/php/$PHP_VERSION/fpm/pool.d/www.conf

# Arrancar
sudo systemctl restart nfs-kernel-server php$PHP_VERSION-fpm
sudo systemctl enable nfs-kernel-server php$PHP_VERSION-fpm

# Eliminar NAT
sudo ip route del default

