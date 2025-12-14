# Infraestructura de 4 Niveles: Aprovisionamiento con Vagrant
Infraestructura en 4 niveles: un balanceador web, un cluster de dos servidores web, un servidor NFS, un balanceador de base de datos, y un cluster de dos servidores de base de datos.

## Índice

* [1. Arquitectura](#1-arquitectura)
* [2. Requisitos Previos](#2-requisitos-previos)
* [3. Configuración del Vagrantfile](#3-configuración-del-vagrantfile)
  * [3.1. ¿Qué es el Vagrantfile?](#31-qué-es-el-vagrantfile)
  * [3.2. Configuración](#32-configuración)
* [4. Script de Aprovisionamiento: Mysql](#4-script-de-aprovisionamiento-mysql)
  * [4.1. Declaración de Variables](#41-declaración-de-variables)
  * [4.2. Actualización e Instalación de MariaDB](#42-actualización-e-instalación-de-mariadb)
  * [4.3. Eliminación de la Puerta de Enlace NAT](#43-eliminación-de-la-puerta-de-enlace-nat)
  * [4.4. Modificación del `bind-address`](#44-modificación-del-bind-address)
  * [4.5. Creación de la base de datos](#45-creación-de-la-base-de-datos)
  * [4.6. Importación del archivo SQL](#46-importación-del-archivo-sql)
* [5. Script de Aprovisionamiento: Apache](#5-script-de-aprovisionamiento-apache)
  * [5.1. Declaración de Variables](#51-declaración-de-variables)
  * [5.2. Actualización e Instalación de Aplicaciones](#52-actualización-e-instalación-de-aplicaciones)
  * [5.3. Despliegue de Código](#53-despliegue-de-código)
  * [5.4. Permisos](#54-permisos)
  * [5.5. Configuración de la Aplicación](#55-configuración-de-la-aplicación)
  * [5.6. Activación del Módulo `mod_rewrite`](#56-activación-del-módulo-mod_rewrite)
* [6. Comprobación y Uso](#6-comprobación-y-uso)
* [7. Conclusión](#7-conclusión)
---

## 1\. Arquitectura.

La infraestructura se distribuye en siete máquinas virtuales, creando capas de aislamiento esenciales para la alta disponibilidad y la seguridad.

| Máquina | Función | IP |
| --- | --- | --- |
| **balanceadorCristina** | Balanceador Web | `192.168.10.5` |
| **server1Cristina** | Servidor Web | `192.168.10.10` `192.168.20.10` |
| **server2Cristina** | Servidor Web | `192.168.10.20` `192.168.20.20`|
| **serverNFSCristina** | Servidor NFS | `192.168.10.30` `192.168.20.30` |
| **proxyDBCristina** | Balanceador de Base de Datos | `192.168.20.5` `192.168.30.5` |
| **serverDB1Cristina** | Servidor de Base de Datos | `192.168.30.40` |
| **serverDB2Cristina** | Servidor de Base de Datos | `192.168.30.50` |
 
El tráfico se gestiona mediante tres subredes:

* red_www: utilizada por el balanceador y los servidores web servidos por el NFS.
* red_cluster: utilizada por los servidores web, NFS y el balanceador de base de datos.
* red_bd: utlizada por los servidores web y la base de datos para gestionar las peticiones MySQL.

El balanceador debe disponer de dos adaptadores de red: la NAT, que viene por defecto, para comunicarse con el exterior, y una red interna privada.

-----

## 2\. Requisitos Previos.

Se requiere tener instalados al menos los siguientes programas:

* **VirtualBox** (Software de virtualización). Descargar [aquí](https://www.virtualbox.org/wiki/Downloads).
* **Vagrant** (Herramienta para la creación y configuración de entornos de desarrollo virtualizados). Descargar [aquí](https://developer.hashicorp.com/vagrant/downloads).
* **Git** (Opcional, pero recomendado) para clonar este repositorio o obtener la carpeta db y src de [https://github.com/josejuansanchez/iaw-practica-lamp.git](https://github.com/josejuansanchez/iaw-practica-lamp.git).

La estructura de carpetas necesaria es la siguiente:

```bash
[Directorio]
├── Vagrantfile
├── balanceador.sh
├── proxyDB.sh
├── server_db.sh
├── server_nfs.sh
├── server_web.sh
├── db/
│   └── database.sql  (Database, tablas, usuarios)
└── src/
    └── index.php, config.php, etc. (El código de la aplicación)
```

A continuación, se explicará cómo configurar el Vagrantfile y los cinco scripts de aprovisionamiento.

-----

## 3\. Configuración del Vagrantfile.


### 3.1\. ¿Qué es el Vagrantfile?

El `Vagrantfile` es un archivo de configuración para el entorno virtualizado. Define los parámetros de las máquinas virtuales (VMs), como la imagen base (`box`), las direcciones IP, los puertos, las carpetas compartidas, y las instrucciones de aprovisionamiento.


### 3.2\. Configuración.

La configuración se basa en la imagen `debian/bookworm64` para ambas máquinas virtuales, asegurando la consistencia del entorno.

Con `config.vm.box` se indica la imagen del sistema operativo; en este caso, Debian (Debian 12).

![Vagrantfile box)](images/vagrantfile_box.png)

Para ambas máquinas, es necesario definir los siguientes parámetros que establecen la estructura de la arquitectura:

* `config.vm.define`: Define el nombre que se usará para referirse a la VM en los comandos de Vagrant (por ejemplo: `vagrant up crisalmmysql`).
* `vm.network "private_network", ip: ...`: Asigna una IP estática en una red privada.
* `vm.provision "shell"`: Indica la ruta del script (`path`) que se ejecutará automáticamente al arrancar la máquina. Con `args` se le da a conocer la IP de la otra máquina.

![Vagrantfile mysql)](images/vagrantfile_mysql.png)

En el caso del servidor web, es imprescindible mapear un puerto para que el usuario acceda a la aplicación. 
* `vm.network "forwarded_port", guest: 80 , host: 8080`: Reenviar el tráfico del puerto de la máquina física (`host`) al puerto de la VM (`guest`).

![Vagrantfile apache)](images/vagrantfile_apache.png)

-----
    
## 4\. Script de Aprovisionamiento: Mysql.

Este script se encarga de instalar y configurar el servidor de base de datos.


### 4.1. Declaración de Variables.

Se definen variables para almacenar datos importantes que se repetirán en varias partes del script.

![mysql variables)](images/mysql_variables.png)

`APACHE_HOST="$1"` captura la IP del servidor web, pasada por `args` en el Vagrantfile.
`SQL_FILE="/vagrant/db/database.sql"` indica la ruta donde se encuentra el archivo que contiene los datos iniciales de la aplicación. Accede a él desde una **carpeta compartida** vagrant que el programa crea automáticamente.


### 4.2. Actualización e Instalación de MariaDB.

Siempre se recomienda actualizar el sistema operativo, asegurando que tenga las versiones más recientes y estables del software. Después, se instala el sistema gestor de base de datos, en este caso, MariaDB. `-y` automatiza el proceso de confirmación.

![mysql install)](images/mysql_install.png)


### 4.3. Eliminación de la Puerta de Enlace NAT.

Para que el servidor no tenga salida a Internet, se elimina la puerta de enlace por defecto (el adaptador NAT implícito que usa VirtualBox). 

![mysql gateway eliminado)](images/mysql_deleteIP.png)


### 4.4. Modificación del `bind-address`.

Es necesario modificar la configuración del servicio MariaDB para que acepte conexiones desde la red privada, permitiendo que el servidor web acceda a la base de datos. El archivo donde se modifica el `bind-address` es: `/etc/mysql/mariadb.conf.d/50-server.cnf`.
Por defecto, MySQL solo escucha en la IP del localhost (`127.0.0.1`). Con el comando `sed` se cambia la directiva, para que MariaDB escuche en todas las interfaces de red internas. Se puede poner directamente la IP del servidor web (`192.168.50.11`), que ofrece más seguridad; en cambio, `0.0.0.0` auemnta la escalabilidad y flexibilidad.

![mysql bind-address)](images/mysql_escuchar.png)

No hay que olvidar el comando `systemctl restart mariadb` para reiniciar MariaDB para que se apliquen los cambios.


### 4.5. Creación de la base de datos.

Con `sudo mysql -u root <<EOF` se abre una sesión de MySQL como usuario `root` y le dice al script que lea todas las siguientes líneas hasta encontrar `EOF`. Esto evita tener que ejecutar los comandos uno por uno en Bash.

![mysql create database)](images/mysql_createDB.png)

Las sentencias SQL son las siguientes:

* `CREATE DATABASE IF NOT EXISTS $DB_NAME`: Crea la base de datos. Con el parámetro `CHARSET utf8mb4` se asegura la compatibilidad con caracteres modernos.
* `CREATE USER '$DB_USER'@'$APACHE_HOST' IDENTIFIED BY '$DB_PASS'`: Crea el usuario `user`, le indica que la conexión será con la IP del servidor web y con la contraseña `pass`.
* `GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'$APACHE_HOST'`: Otorga todos los permisos al usuario creado.
* `FLUSH PRIVILEGES`: Orden para aplicar los permisos otorgados.

Con el comando `echo` se le dice que muestre los mensajes de confirmación deseados. 

Es importante no olvidar que las sentencias SQL terminan siempre con `;`.


### 4.6. Importación del archivo SQL.

Para finalizar, hay que importar el archivo `database.sql` que contiene las sentencias necesarias para la creación de las tablas que usará la aplicación. 

![mysql importación del .sql)](images/mysql_sqlFile.png)

Este bloque `if` comprueba primero si la ruta es correcta y si el archivo existe. Después, le pasa el fichero a la base de datos (`sudo mysql -u root $DB_NAME < "$SQL_FILE"`). Si falla, mostrará un mensaje de error.

Con esto, el script de aprovisionamiento de MySQL estaría completo.

-----

## 5\. Script de Aprovisionamiento: Apache.

Este script se encarga de instalar y configurar el servidor web.


### 5.1. Declaración de Variables.

Se definen variables para almacenar datos importantes que se repetirán en varias partes del script.

![apache variables)](images/apache_variables.png)

Igual que el script anterior, `DB_HOST="$1"` captura la IP del servidor de base de datos, pasada por `args` en el Vagrantfile.


### 5.2. Actualización e Instalación de Aplicaciones.

Se actualiza primero el sistema operativo. A continuación, se instala los componentes clave de la pila LAMP: Apache2 (servidor web), PHP (lenguaje de programación), `libapache2-mod-php` (módulo para que Apache ejecute PHP) y `php-mysql` (el módulo que permite a PHP conectar con MariaDB/MySQL).

![apache install)](images/apache_install.png)


### 5.3. Despliegue de Código.

En este caso, para evitar posibles conflictos con los nombres de los archivos, se elimina (`rm -f`) la página web de bienvenida predeterminada de Apache (`index.html`), que se encuentra en `/var/www/html`.

![apache files)](images/apache_files.png)

A continuación, se copia de manera todo el contenido de la carpeta compartida (`/vagrant/src`) al directorio actual (`.`), que es todo el código de la aplicación.


### 5.4. Permisos.

El directorio `/var/www/html` necesita tener los permisos correctos para que el servidor web pueda leerlo y ejecutarlo. 

Con el comando `chmod -R 755` se asigna los permisos de lectura y escritura a los archivos dentro del directorio; el propietario tendrá el control total, y otros usuarios no podrán modificarlos.

El usuario Apache por defecto es `www-data`. El comando `chown -R www-data:www-data "$WEB_ROUTE"` cambia la propiedad de los archivos al usuario y grupo de Apache.

![apache permisos)](images/apache_permisos.png)


### 5.5. Configuración de la Aplicación.

Este bloque `if` comprueba primero si la ruta es correcta y si el archivo `config.php` existe.

`sed` se utiliza para buscar (`s/`) y reemplazar (`/g`) el texto deseado directamente en el archivo (`-i`).

![apache config)](images/apache_config.png)


### 5.6. Activación del Módulo `mod_rewrite`.

Para que la aplicación funcione correctamente, se requiere activar `mod_rewrite`, un módulo que, por así decirlo, actúa como traductor entre el usuario y la aplicación. Reescribe la URL que el usuario escribe a a la sintaxis interna que el código PHP entiende. Se activa con el comando `a2enmod rewrite`.

![apache habilitar)](images/apache_habilitar.png)

Por último, se reinicia el servicio Apache (`systemctl restart apache2`) para que se apliquen todos los cambios realizados.

-----

## 6\. Comprobación y Uso.

Para levantar la arquitectura, simplemente se ejecuta el siguiente comando en el directorio raíz: `vagrant up`.

Una vez que ambas máquinas estén encendidas, para verificar el funcionamiento de la aplicación:

  1. En un navegador web, introducir la URL: `http://localhost:8080`. 
  2. Probar la aplicación. Introducir, visualizar y borrar datos para comprobar su correcto funcionamiento.

[![Ver video](images/comprobacion.png)](https://www.canva.com/design/DAG5m7j1dHA/ujCRUtqkkVI6YOF6tu4RvQ/watch?utm_content=DAG5m7j1dHA&utm_campaign=designshare&utm_medium=link2&utm_source=uniquelinks&utlId=h0c8ec7e6e0)

(Haz click en la imagen para ver el vídeo)

## 7\. Conclusión.

El objetivo de este práctica era diseñar y automatizar una arquitectura de dos niveles segura. Se ha logrado mediante el uso de Vagrant, junto con los scripts de aprovisionamiento. 

Como resultado, se ha obtenido una aplicación web perfectamente funcional.
