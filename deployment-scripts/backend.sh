#!/bin/bash

#Colors
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"

# --- CONFIG ---
DB_NAME="ss_demo_1"
DB_USER="postgres"
DB_PASS="postgres"
TOMCAT_USER="admin"
TOMCAT_PASS="AdminLocal!"
APP_URL="https://github.com/PeterIanush/Geocitizen.git"

clone_app() {
	echo -e "${YELLOW}Cloning application...${NC}"
	git clone $APP_URL
	cd Geocitizen
}

modify_pom() {
  echo -e "${YELLOW}Modifying pom.xml${NC}"
  
  # Add Maven Central (HTTPS)
  sed -i '/<repositories>/a \
    <repository>\
        <id>central</id>\
        <url>https://repo.maven.apache.org/maven2</url>\
        <snapshots>\
            <enabled>false</enabled>\
        </snapshots>\
    </repository>' pom.xml

  # Add missing javax to servlet-api
  sed -i 's/<artifactId>servlet-api<\/artifactId>/<artifactId>javax.servlet-api<\/artifactId>/' pom.xml

  # Fix facebook social dependency version (2.0.3.RELEASE)
  sed -i 's/<springframework.social.facebook.version>.*<\/springframework.social.facebook.version>/<springframework.social.facebook.version>2.0.3.RELEASE<\/springframework.social.facebook.version>/' pom.xml

  # Fix gauth2 typo
  sed -i 's/security.gauth2/security.oauth2/g' pom.xml
  
  echo -e "${GREEN}pom.xml updated successfully${NC}"
}

install_dependencies() {
	echo -e "${YELLOW}Installing dependencies...${NC}"
	sudo apt update
	sudo apt install -y openjdk-11-jdk maven git postgresql postgresql-contrib tomcat10 tomcat10-admin
}

configure_postgres() {
	echo -e "${YELLOW}Configuring postgres...${NC}"
	sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
	sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER;"
	sudo -u postgres psql -c "ALTER USER $DB_USER CREATEDB;"
}

configure_tomcat() {
	echo -e "${YELLOW}Configuring Tomcat...${NC}"

	sudo bash -c "cat <<EOL > /etc/tomcat10/tomcat-users.xml
	<?xml version=\"1.0\" encoding=\"UTF-8\"?>
	<tomcat-users xmlns=\"http://tomcat.apache.org/xml\"
								xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
								xsi:schemaLocation=\"http://tomcat.apache.org/xml tomcat-users.xsd\"
								version=\"1.0\">
		<role rolename=\"manager-gui\"/>
		<role rolename=\"manager-script\"/>
		<user username=\"$TOMCAT_USER\" password=\"$TOMCAT_PASS\" 
					roles=\"manager-gui,manager-script\"/>
	</tomcat-users>
	EOL"
}

configure_application_properties() {
	echo -e "${YELLOW}set application properties...${NC}"
}

build_app() {
	echo -e "${YELLOW}Building application...${NC}"
	mvn install 
}

deploy_app() {
	echo -e "${YELLOW}Deploying application...${NC}"
	sudo systemctl stop tomcat10
	sudo rm /var/lib/tomcat10/webapps/citizen.war
	sudo cp target/citizen.war /var/lib/tomcat10/webapps
	sudo chown tomcat:tomcat /var/lib/tomcat10/webapps/citizen.war
	sudo systemctl restart postgresql
	sudo systemctl restart tomcat10
}

install_dependencies
configure_postgres
configure_tomcat
clone_app
configure_application_properties
modify_pom
build_app
deploy_app
