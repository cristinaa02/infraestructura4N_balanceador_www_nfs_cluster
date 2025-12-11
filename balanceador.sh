#!/bin/bash

# variables de entorno
SERVER1_IP_WWW="192.168.10.10"
SERVER2_IP_WWW="192.168.10.20"

# set -e
# sudo hostnamectl set-hostname BalanceadorCrisAlm

# Actualizar el sistema e instalar NGINX.
sudo apt update 
sudo apt install -y nginx

# Reiniciar NGINX
sudo systemctl restart nginx

# Crear archivo de configuración del proxy inverso.
cd /etc/nginx/sites-enabled


# Reiniciar NGINX
sudo systemctl restart nginx
