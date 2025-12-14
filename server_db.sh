#!/bin/bash

# VARIABLES
CLUSTER_NODES="192.168.30.40,192.168.30.50"
HOSTNAME=$(hostname)
PASS="pass" 
SQL_FILE_PATH="/vagrant/db/database.sql" 

# Detectar la IP
if [ "$HOSTNAME" == "serverDB1Cristina" ]; then
    NODO_IP="192.168.30.40"
    IS_BOOTSTRAP_NODE=true
else
    NODO_IP="192.168.30.50"
    IS_BOOTSTRAP_NODE=false
fi

sudo apt update -y

# Instalación desatendida
DEBIAN_FRONTEND=noninteractive sudo apt install -y mariadb-server mariadb-client galera-4

# Detener el servicio antes de aplicar la configuración de Galera
sudo systemctl stop mariadb

# Configuración de Galera
sudo tee /etc/mysql/mariadb.conf.d/60-galera.cnf << EOF
[galera]
wsrep_on                 = ON
wsrep_cluster_name       = "galera_cluster"
wsrep_provider           = /usr/lib/galera/libgalera_smm.so
wsrep_cluster_address    = gcomm://$CLUSTER_NODES
binlog_format            = row
default_storage_engine   = InnoDB
innodb_autoinc_lock_mode = 2
wsrep_sst_method         = mariabackup
wsrep_sst_auth           = "root:$PASS"

# Propiedades del nodo actual
bind-address = 0.0.0.0
wsrep_node_address=$NODO_IP
wsrep_node_name=$HOSTNAME
EOF

# Cluster
if [ "$IS_BOOTSTRAP_NODE" = true ]; then

    # Iniciar el cluster como bootstrap
    sudo galera_new_cluster
    sleep 15
    
    # Configurar contraseña de root
    sudo mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$PASS');"
    
    # Crear usuario para HAProxy health checks
    sudo mysql -u root -p"$PASS" -e "CREATE USER IF NOT EXISTS 'haproxy'@'%';"
    sudo mysql -u root -p"$PASS" -e "FLUSH PRIVILEGES;"
    
    # Crear usuario de aplicación
    sudo mysql -u root -p"$PASS" -e "CREATE USER IF NOT EXISTS 'user'@'%' IDENTIFIED BY '$PASS';"
    sudo mysql -u root -p"$PASS" -e "GRANT ALL PRIVILEGES ON *.* TO 'user'@'%' WITH GRANT OPTION;"
    sudo mysql -u root -p"$PASS" -e "FLUSH PRIVILEGES;"
    
    # Importar archivo SQL si existe
    if [ -f "$SQL_FILE_PATH" ]; then
        echo "Importando base de datos desde $SQL_FILE_PATH"
        sudo mysql -u root -p"$PASS" < "$SQL_FILE_PATH"
        echo "✓ Base de datos importada correctamente"
    else
        echo " Archivo SQL no encontrado en $SQL_FILE_PATH"
    fi

else
    # Nodo secundario: solo iniciar MariaDB
    sudo systemctl start mariadb
    sleep 10
fi

# Habilitar el servicio
sudo systemctl enable mariadb

# Verificar estado del cluster
sleep 2
echo "=== Estado del nodo ==="
sudo mysql -u root -p"$PASS" -e "SHOW STATUS LIKE 'wsrep_cluster_size';" 2>/dev/null || echo "Esperando sincronización..."