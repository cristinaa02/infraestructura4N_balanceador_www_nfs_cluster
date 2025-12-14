#!/bin/bash

# --- VARIABLES ---
DB1_IP="192.168.30.40"
DB2_IP="192.168.30.50"

# Instalación
sudo apt update -y
sudo apt install -y haproxy mariadb-client

# Habilitar servicio, por si acaso
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
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

listen mysql-cluster
    bind *:3306
    mode tcp
    balance roundrobin
    option mysql-check user haproxy password pass
    server db1 ${DB1_IP}:3306 check
    server db2 ${DB2_IP}:3306 check

listen stats
    bind *:8080
    mode http
    stats enable
    stats uri /stats
    stats refresh 30s
    stats realm HAProxy\ Statistics
    stats auth admin:admin
EOF

# Reiniciar HAProxy
sudo systemctl restart haproxy
sudo systemctl enable haproxy

# Eliminar NAT
sudo ip route del default