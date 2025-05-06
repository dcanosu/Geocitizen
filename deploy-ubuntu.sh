#!/bin/bash
set -e

PROJECT_PATH="/usr/local/projects/Geocitizen"
DEPLOY_LOG="/var/logs/geocitizen/logs/deploy.log"

echo "➡️  Creando carpeta de logs"
sudo mkdir -p /var/logs/geocitizen/logs
# sudo chmod +w /var/logs/geocitizen/logs

echo "➡️  Clonando repositorio"
echo "$(date) - Clonando el repositorio..." >> "$DEPLOY_LOG"
git clone https://github.com/PeterIanush/Geocitizen.git "$PROJECT_PATH" >> "$DEPLOY_LOG" 2>&1
echo ✅"El repositorio fue clonado exitoxamente"

echo "➡️  Cambiando de directorio"
# Entra al directorio (cambia si el nombre del repo es diferente)
cd $PROJECT_PATH

echo "➡️  Haciendo copia del pom.xml"
# Hace una copia del pom.xml original
cp pom.xml pom.xml.bak

echo "➡️  Cambiando version de facebook"
# Cambiar en la línea 37 la versión de Facebook
# sed -i '37s|<springframework.social.facebook.version>3\.0\.0\.M3</springframework.social.facebook.version>|<springframework.social.facebook.version>2.0.3.RELEASE</springframework.social.facebook.version>|' pom.xml
sed -i 's|<springframework.social.facebook.version>3\.0\.0\.M3</springframework.social.facebook.version>|<springframework.social.facebook.version>2.0.3.RELEASE</springframework.social.facebook.version>|' pom.xml

echo "➡️  Cambiando servlet-api por javax.servlet-api"
# Cambiar en la línea 199 el nombre del artefacto
sed -i 's|<artifactId>servlet-api</artifactId>|<artifactId>javax.servlet-api</artifactId>|' pom.xml

echo "➡️  Añadiendo la versión de maven-war"
# Añadir una nueva línea despues de la 500 con la version
sed -i '500s|<artifactId>maven-war-plugin</artifactId>|<artifactId>maven-war-plugin</artifactId>\n                <version>3.3.2</version>|' pom.xml

echo "➡️  Añadiendo una nueva línea después de la 584"
sed -i '584a\
        <repository>\
            <id>central</id>\
            <url>https://repo.maven.apache.org/maven2</url>\
            <snapshots>\
                <enabled>false</enabled>\
            </snapshots>\
        </repository>\' pom.xml

echo "✅ ¡Listo! pom.xml modificado. Se guardó copia como pom.xml.bak"


# echo "➡️  Compilando el proyecto"
# cd "$PROJECT_PATH"
# mvn clean install >> "$DEPLOY_LOG" 2>&1

# echo "➡️  Copiando .war a Tomcat"
# sudo cp target/citizen.war /opt/tomcat/webapps/

# echo "✅ Despliegue completado"
