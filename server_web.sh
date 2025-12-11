#!/bin/bash

# variables de entorno
NFS_IP_WWW="192.168.10.30"
WP_DIR_NFS="/var/www/wordpress"
DIR="/var/www/html"

set -e
sudo hostnamectl set-hostname WebCrisAlm

# Instalar Apache, PHP (con módulos), MySQL Client y NFS Client
sudo apt update 
sudo apt install -y apache2 php libapache2-mod-php php-mysql nfs-common curl

sudo systemctl stop apache2
sudo rm -rf $DIR/*

# Crear el directorio local a de montar.
sudo mkdir -p $DIR

# Montar la carpeta compartida.
# sudo mount $NFS_IP_WWW:$WP_DIR_NFS $DIR
echo "$NFS_IP_WWW:$WP_DIR_NFS $DIR nfs defaults,timeo=900,retrans=5,_netdev 0 0" | sudo tee -a /etc/fstab
sudo mount -a
if mountpoint -q $DIR; then
    echo "Montaje de NFS en $DIR."
else
    echo "ERROR: Fallo al montar la carpeta NFS"
    exit 1 # Detiene el script si el montaje falla.
fi

# Descargar WP-CLI
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

WP_CLI_DIR="/var/www/html"

# Personalizar contenido del sitio

sudo -u www-data wp core install \
    --url="https://iawcris.ddns.net" \
    --title="IAW Web Cristina" \
    --admin_user="admin" \
    --admin_password="123" \
    --admin_email="admin@admin.com" \
    --path=$WP_CLI_DIR \
    --skip-email

# 1. Borrar la entrada por defecto ("¡Hola, mundo!")
sudo -u www-data wp post delete 1 --force --path=$WP_CLI_DIR || true

# 2. Crear una nueva página estática
HOME_PAGE_ID=$(sudo -u www-data wp post create --post_type=page --post_title='Página de Inicio Wordpress de Cris' --post_status=publish --post_content='¡Bienvenido/a a Wordpress desde AWS!' --path=$WP_CLI_DIR --porcelain)
# BLOG_PAGE_ID=$(sudo -u www-data wp post create --post_type=page --post_title='Blog y Noticias' --post_status=publish --path=$WP_CLI_DIR --allow-root --porcelain)
# 4. Configurar WordPress para usar la página estática
sudo -u www-data wp option update show_on_front 'page' --path=$WP_CLI_DIR
sudo -u www-data wp option update page_on_front $HOME_PAGE_ID --path=$WP_CLI_DIR
# sudo -u www-data wp option update page_for_posts $BLOG_PAGE_ID --path=$WP_CLI_DIR --allow-root

# SSL
sudo apt install -y ssl-cert
sudo a2enmod ssl headers

# Generar un certificado autofirmado
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/iawcris.key \
    -out /etc/ssl/certs/iawcris.crt \
    -subj "/CN=iawcris.ddns.net"

# Configurando HTTP
sudo tee /etc/apache2/sites-available/wordpress.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName iawcris.ddns.net
    DocumentRoot $DIR
    
    <Directory $DIR>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/balancer_http_error.log
    CustomLog ${APACHE_LOG_DIR}/balancer_http_access.log combined
</VirtualHost>
EOF

# Configuración HTTPS
sudo tee /etc/apache2/sites-available/wordpress-ssl.conf > /dev/null <<EOF
<VirtualHost *:443>
    ServerName iawcris.ddns.net
    DocumentRoot $DIR

    # Rutas del certificado generado
    SSLEngine on
    SSLCertificateFile    /etc/ssl/certs/iawcris.crt
    SSLCertificateKeyFile /etc/ssl/private/iawcris.key

    <Directory $DIR>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/ssl_error.log
    CustomLog ${APACHE_LOG_DIR}/ssl_access.log combined
</VirtualHost>
EOF

# Habilitar SSL
sudo a2dissite 000-default.conf
sudo a2ensite wordpress.conf
sudo a2ensite wordpress-ssl.conf

# # Permisos para acceder a los archivos.
# sudo chown -R www-data:www-data $DIR

sudo systemctl restart apache2