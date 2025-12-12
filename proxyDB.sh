#!/bin/bash

# Variables
DB1_IP="192.168.30.40"
DB2_IP="192.168.30.50"

# Actualizar e instalar HAProxy
sudo apt update -y
sudo apt install -y haproxy

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
    option mysql-check user haproxy
    timeout connect 5000
    timeout client 50000
    timeout server 50000

listen galera_cluster
    bind *:3306
    mode tcp
    option tcpka
    option mysql-check user haproxy
    balance source
    server db1 ${DB1_IP}:3306 check
    server db2 ${DB2_IP}:3306 check

listen stats
    bind *:8080
    mode http
    stats enable
    stats uri /
    stats realm Strictly\ Private
    stats auth admin:adminpass
EOF

# Usuario HAProxy
mysql -u root -h${DB1_IP} << EOF2 || true
CREATE USER IF NOT EXISTS 'haproxy'@'%' IDENTIFIED BY 'pass';
GRANT PROCESS ON *.* TO 'haproxy'@'%';
FLUSH PRIVILEGES;
EOF2
mysql -u root -h${DB2_IP} << EOF3 || true
CREATE USER IF NOT EXISTS 'haproxy'@'%' IDENTIFIED BY 'pass';
GRANT PROCESS ON *.* TO 'haproxy'@'%';
FLUSH PRIVILEGES;
EOF3

# Reiniciar HAProxy
sudo systemctl restart haproxy
sudo systemctl enable haproxy

# Eliminar NAT
sudo ip route del default
