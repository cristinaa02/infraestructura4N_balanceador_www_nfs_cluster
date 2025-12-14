#!/bin/bash

NFS_SERVER="192.168.20.30"
WEB_ROUTE="/var/www/html"

# Instalar Nginx, PHP-FPM y NFS client
sudo apt update
sudo apt install -y nginx php-fpm nfs-common

# Crear directorio para montaje NFS
sudo mkdir -p "$WEB_ROUTE"

# Configurar montaje automático NFS
if ! grep -q "$NFS_SERVER:$WEB_ROUTE" /etc/fstab; then
    echo "$NFS_SERVER:$WEB_ROUTE $WEB_ROUTE nfs defaults,_netdev 0 0" | sudo tee -a /etc/fstab
fi

# Intentar montar NFS con reintentos
MAX_RETRIES=5
RETRY=0
while [ $RETRY -lt $MAX_RETRIES ]; do
    if sudo mount "$NFS_SERVER:$WEB_ROUTE" "$WEB_ROUTE" 2>/dev/null; then
        echo "✓ NFS montado correctamente"
        break
    else
        RETRY=$((RETRY+1))
        echo "Intento $RETRY de $MAX_RETRIES: esperando al servidor NFS..."
        sleep 5
    fi
done

if [ $RETRY -eq $MAX_RETRIES ]; then
    echo "✗ ERROR: No se pudo montar NFS después de $MAX_RETRIES intentos"
    exit 1
fi

# Configuración Nginx
sudo tee /etc/nginx/sites-available/app << EOF
server {
    listen 80;
    server_name _;
    root $WEB_ROUTE;
    index index.php index.html;

    # Logs
    access_log /var/log/nginx/app_access.log;
    error_log /var/log/nginx/app_error.log;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        fastcgi_pass $NFS_SERVER:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        
        # Timeouts para evitar 504
        fastcgi_connect_timeout 60s;
        fastcgi_send_timeout 60s;
        fastcgi_read_timeout 60s;
    }
}
EOF

# Activar sitio y desactivar default
sudo ln -sf /etc/nginx/sites-available/app /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Verificar configuración de Nginx
if sudo nginx -t; then
    sudo systemctl restart nginx
    sudo systemctl enable nginx
    echo "✓ Nginx configurado y activo"
else
    echo " ERROR: Configuración de Nginx inválida"
    exit 1
fi

# Eliminar ruta NAT
sudo ip route del default 2>/dev/null || true

echo "=== Servidor Web configurado ==="