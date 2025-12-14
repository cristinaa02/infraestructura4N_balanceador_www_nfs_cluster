#!/bin/bash

# --- VARIABLES ---
DB1_IP="192.168.30.40"
DB2_IP="192.168.30.50"

# Instalación
sudo apt update -y
sudo apt install -y haproxy mariadb-client

# Habilitar servicio
echo "ENABLED=1" | sudo tee /etc/default/haproxy

# Configuración HAProxy
sudo tee /etc/haproxy/haproxy.cfg << EOF
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log global
    mode tcp
    option tcplog
    timeout connect 10s
    timeout client 60s
    timeout server 60s

listen mysql-cluster
    bind *:3306
    mode tcp
    balance roundrobin
    option mysql-check user haproxy
    server db1 ${DB1_IP}:3306 check
    server db2 ${DB2_IP}:3306 check

listen stats
    bind *:8080
    mode http
    stats enable
    stats uri /stats
    stats refresh 10s
    stats realm HAProxy\ Statistics
    stats auth admin:admin
    stats show-legends
    stats show-node
EOF

# Reiniciar HAProxy
sudo systemctl restart haproxy
sudo systemctl enable haproxy

# Verificar que HAProxy está escuchando
sleep 2
if sudo ss -tlnp | grep :3306 > /dev/null 2>&1; then
    echo "✓ HAProxy escuchando en puerto 3306"
else
    echo "✗ ERROR: HAProxy no está escuchando en puerto 3306"
    sudo systemctl status haproxy
fi

# Eliminar ruta NAT
sudo ip route del default 2>/dev/null || true

echo "=== HAProxy configurado ==="
echo "Estadísticas disponibles en: http://192.168.20.5:8080/stats"
echo "Usuario: admin / Contraseña: admin"