#!/bin/bash

WEB1_IP="192.168.10.10"
WEB2_IP="192.168.10.20"

# Instalar Nginx
sudo apt update
sudo apt install -y nginx

# Config balanceador
sudo tee /etc/nginx/conf.d/load-balancer.conf << EOF
upstream backend_servers {
    server $WEB1_IP:80;
    server $WEB2_IP:80;
}

server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://backend_servers;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Activar
sudo ln -s /etc/nginx/conf.d/load-balancer.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx