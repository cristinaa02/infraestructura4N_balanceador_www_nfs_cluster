#!/bin/bash

NFS_SERVER="192.168.20.30"
WEB_ROUTE="/var/www/html"

# Instalar Nginx
sudo apt update
sudo apt install -y nginx nfs-common

# Montar NFS
sudo mkdir -p "$WEB_ROUTE"
echo "$NFS_SERVER:$WEB_ROUTE $WEB_ROUTE nfs defaults 0 0" | sudo tee -a /etc/fstab
sudo mount "$NFS_SERVER:$WEB_ROUTE" "$WEB_ROUTE"

# Config Nginx
sudo tee /etc/nginx/sites-available/app << EOF
server {
    listen 80;
    server_name _;
    root $WEB_ROUTE;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        fastcgi_pass $NFS_SERVER:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/app /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx

# Eliminar NAT
sudo ip route del default