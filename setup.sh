#!/bin/bash
set -e

echo "➡️  Actualizando paquetes"
sudo apt-get update && sudo apt-get upgrade -y

echo "➡️  Instalando herramientas necesarias"
sudo apt-get install -y \
    git \
    nano \
    maven \
    openjdk-8-jdk \
    wget \
    unzip \
    curl \
    net-tools \
    python3 \
    make \
    g++ \
    xz-utils \
    openssh-server

sudo systemctl enable ssh
sudo systemctl start ssh

echo "➡️  Creando ruta de Python3 como python"
sudo ln -sf /usr/bin/python3 /usr/bin/python

echo "➡️  Instalando Tomcat 9"
TOMCAT_VERSION="9.0.50"
cd /tmp
wget https://archive.apache.org/dist/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz
sudo tar -xvzf apache-tomcat-${TOMCAT_VERSION}.tar.gz -C /opt
sudo ln -sf /opt/apache-tomcat-${TOMCAT_VERSION} /opt/tomcat
rm apache-tomcat-${TOMCAT_VERSION}.tar.gz
sudo chmod -R +rx /opt/tomcat/bin
sudo nano /etc/systemd/system/tomcat.service

echo "➡️  Configurando servicio systemd para Tomcat"

# Crea el archivo de servicio para Tomcat
sudo tee /etc/systemd/system/tomcat.service > /dev/null <<EOF
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/lib/jvm/java-8-openjdk-arm64
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
User=$(whoami)
Group=$(whoami)
UMask=0007

[Install]
WantedBy=multi-user.target
EOF

# Recarga systemd para reconocer el nuevo servicio
sudo systemctl daemon-reload
# Habilita Tomcat para que arranque con el sistema
sudo systemctl enable tomcat
# Inicia el servicio Tomcat
sudo systemctl start tomcat

echo "➡️  Instalando Node js v.14"
NODEJS_VERSION="v14.21.3"
ARCHITECTURE="arm64" #x64
cd /tmp
curl -sL https://nodejs.org/dist/${NODEJS_VERSION}/node-${NODEJS_VERSION}-linux-${ARCHITECTURE}.tar.xz -o node-${NODEJS_VERSION}-linux-${ARCHITECTURE}.tar.xz
sudo tar -xJf node-${NODEJS_VERSION}-linux-${ARCHITECTURE}.tar.xz -C /opt
rm node-${NODEJS_VERSION}-linux-${ARCHITECTURE}.tar.xz
# Configuración de Node.js: Añadir al PATH
echo "➡️  Configurando Node.js en el PATH"
echo 'export PATH=/opt/node-${NODEJS_VERSION}-linux-${ARCHITECTURE}/bin:$PATH' | sudo tee -a /etc/profile.d/nodejs.sh
# Recargar el archivo de configuración de perfil para que la variable de entorno se aplique
source /etc/profile.d/nodejs.sh

echo "✅ Node.js v14 instalado correctamente"
echo "➡️  Instalando Npm"
sudp apt-get install npm -y

# Verificar versiones instaladas
echo "➡️  Verificando versiones de Tomcat y Node.js"
echo "✅ Tomcat9"
echo "Tomcat Version: $(/opt/tomcat/bin/version.sh)"
echo "✅ Nodejs"
echo "Node.js Version: $(node -v)"
echo "npm Version: $(npm -v)"

echo "➡️  Instalando PostgreSQL"

# Variables
DB_USER="dcanosu"
DB_PASSWORD="Morgan"
DB_NAME="geocitizen_db"

# Instalar PostgreSQL
sudo apt-get update
sudo apt-get install -y postgresql postgresql-contrib

# Iniciar el servicio
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Crear usuario, base de datos y asignar permisos
sudo -u postgres psql <<EOF
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
CREATE DATABASE $DB_NAME OWNER $DB_USER;
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
ALTER USER postgres WITH PASSWORD 'Morgan';
EOF

echo "✅ PostgreSQL instalado y configurado con:"
echo "   Usuario: $DB_USER"
echo "   Base de datos: $DB_NAME"

echo "✅ Setup finalizado"



# EN EL package json   // npm install webpack-dev-server@3 --save-dev
# npm install webpack@4 webpack-cli@3 --save-dev
npm install --save sass-loader sass vue-style-loader css-loader
npm install --save debounce
npm install vue-material@latest
