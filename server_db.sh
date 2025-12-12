#!/bin/bash

# Variables
SQL_FILE="/vagrant/db/database.sql"
CLUSTER_NODES="192.168.30.40,192.168.30.50"

# Instalar MariaDB + Galera
sudo apt update
sudo apt install -y mariadb-server rsync

# Eliminar NAT
sudo ip route del default

# Config Galera
sudo tee -a /etc/mysql/mariadb.conf.d/50-server.cnf << EOF

[mysqld]
bind-address = 0.0.0.0
default_storage_engine=InnoDB
binlog_format=ROW
innodb_autoinc_lock_mode=2

# Galera
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so
wsrep_cluster_address="gcomm://$CLUSTER_NODES"
wsrep_sst_method=rsync
wsrep_node_name="db1"
wsrep_node_address="192.168.30.40"
EOF

# Reiniciar (inicia clúster)
sudo systemctl restart mariadb
sudo systemctl enable mariadb

# Importar el SQL que lo hace TODO
if [ -f "$SQL_FILE" ]; then
    sudo mysql -u root < "$SQL_FILE"
else
    echo "Archivo ${SQL_FILE} no encontrado."
fi
