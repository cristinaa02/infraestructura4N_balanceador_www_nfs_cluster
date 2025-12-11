#!/bin/bash

# variables de entorno
DB_NAME="wordpress_db"
DB_USER="crisalm"
DB_PASS="pass"
IP_SERVER_DB="192.168.20.50"
SERVER1_IP_WWW="192.168.10.10"
SERVER2_IP_WWW="192.168.10.20"
WP_DIR="/var/www/wordpress"

set -e
sudo hostnamectl set-hostname NFSCrisAlm

# Actualizar el sistema e instalar NFS, etc.
sudo apt update 
sudo apt install -y nfs-kernel-server apache2 php wget unzip php-mysql

# Crear el directorio compartido.
sudo mkdir -p $WP_DIR

# Instalar Wordpress
sudo wget -O /tmp/latest.zip https://wordpress.org/latest.zip
sudo unzip -q /tmp/latest.zip -d /tmp
sudo mv /tmp/wordpress/* $WP_DIR/
sudo rm -rf latest.zip wordpress/

# Asignar permisos al usuario de Apache (www-data)
sudo chown -R www-data:www-data $WP_DIR
sudo chmod -R 775 $WP_DIR

sudo cp $WP_DIR/wp-config-sample.php $WP_DIR/wp-config.php

# Configuración de la Aplicación.
CONFIG_FILE=$WP_DIR/wp-config.php

if [ -f "$CONFIG_FILE" ]; then
    # 1. Reemplazamos 'localhost' por la IP privada de MySQL.
    sudo sed -i "s/localhost/$IP_SERVER_DB/g" "$CONFIG_FILE"
    # 2. Reemplazamos el nombre de la BD.
    sudo sed -i "s/database_name_here/$DB_NAME/g" "$CONFIG_FILE"
    # 3. Reemplazamos el usuario por el usuario de la aplicación (variable dinámica).
    sudo sed -i "s/username_here/$DB_USER/g" "$CONFIG_FILE" 
    # 4. Reemplazar la contraseña.
    sudo sed -i "s/password_here/$DB_PASS/g" "$CONFIG_FILE"
    echo "Configuración de DB completada en $CONFIG_FILE. Usuario usado: $DB_USER"
else
    echo "ERROR: Archivo $CONFIG_FILE no encontrado."
fi

# Editar /etc/exports.
sudo echo "$WP_DIR 192.168.10.0/24(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports

# Activar /etc/exports
sudo systemctl restart nfs-kernel-server
sudo exportfs -a


