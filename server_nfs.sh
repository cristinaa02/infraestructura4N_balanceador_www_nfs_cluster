#!/bin/bash

WEB_ROUTE="/var/www/html"
NFS_CLIENT1="192.168.20.10"
NFS_CLIENT2="192.168.20.20"

# Instalar NFS + PHP-FPM
sudo apt update
sudo apt install -y nfs-kernel-server php-fpm php-mysql php-cli php-curl php-gd php-mbstring php-xml php-zip

# Carpeta web NFS
sudo mkdir -p "$WEB_ROUTE"

# Copiar archivos src
cd "$WEB_ROUTE"
sudo rm -f index.html
sudo cp -r /vagrant/src/* . 2>/dev/null || echo "No src folder found"
sudo chown -R www-data:www-data "$WEB_ROUTE"
sudo chmod -R 755 "$WEB_ROUTE"

# Detectar versión de PHP
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
echo "PHP Version detected: $PHP_VERSION"

# Configurar config.php si existe
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
else
    echo "No se encontró config.php, saltando configuración DB"
fi

# Export NFS
echo "$WEB_ROUTE $NFS_CLIENT1(rw,sync,no_subtree_check,no_root_squash)" | sudo tee /etc/exports
echo "$WEB_ROUTE $NFS_CLIENT2(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports
sudo exportfs -ra

# PHP-FPM: Configurar para escuchar en TCP puerto 9000
PHP_FPM_POOL="/etc/php/$PHP_VERSION/fpm/pool.d/www.conf"

# Cambiar de socket Unix a TCP
sudo sed -i "s|^listen = .*|listen = 0.0.0.0:9000|g" "$PHP_FPM_POOL"

# Comentar o eliminar la restricción de allowed_clients
sudo sed -i "s/^listen.allowed_clients/;listen.allowed_clients/g" "$PHP_FPM_POOL"

# Asegurar permisos correctos
sudo sed -i "s/^;listen.owner = www-data/listen.owner = www-data/g" "$PHP_FPM_POOL"
sudo sed -i "s/^;listen.group = www-data/listen.group = www-data/g" "$PHP_FPM_POOL"
sudo sed -i "s/^;listen.mode = 0660/listen.mode = 0660/g" "$PHP_FPM_POOL"

# Reiniciar servicios
sudo systemctl restart nfs-kernel-server
sudo systemctl restart php${PHP_VERSION}-fpm
sudo systemctl enable nfs-kernel-server
sudo systemctl enable php${PHP_VERSION}-fpm

# Verificar que PHP-FPM esté escuchando
sleep 2
if sudo netstat -tlnp | grep :9000 > /dev/null 2>&1 || sudo ss -tlnp | grep :9000 > /dev/null 2>&1; then
    echo "✓ PHP-FPM escuchando en puerto 9000"
else
    echo "✗ ERROR: PHP-FPM no está escuchando en puerto 9000"
    sudo systemctl status php${PHP_VERSION}-fpm
fi

# Eliminar ruta NAT por defecto
sudo ip route del default 2>/dev/null || true

echo "=== Servidor NFS configurado ==="