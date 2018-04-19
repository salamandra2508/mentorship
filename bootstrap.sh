#!/bin/bash

set -x

#describe instance hostname via meta-data
instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

#set new host name
new_host_name=$(sudo hostnamectl set-hostname TEST-$instance_id)

#add new hostname to /etc/hosts file
sudo sh -c "echo '127.0.0.1 TEST-$instance_id ' >> /etc/hosts"

#setup tomcat version
tcver="apache-tomcat-8.0.23"


#Update sustem and install apache, java , wget, mc, htop
sudo apt-get update
sudo apt-get install -y apache2 default-jdk wget mc htop

#Setup sustem for tomcat
sudo groupadd tomcat
sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat
cd ~

#download tomcat
if [[ ! -f /home/ubuntu/$tcver.tar.gz ]]; then
        wget -c https://archive.apache.org/dist/tomcat/tomcat-8/v8.0.23/bin/apache-tomcat-8.0.23.tar.gz
else
	echo "File already download"
fi

sudo mkdir /opt/tomcat

sudo tar xvf apache-tomcat-8*tar.gz -C /opt/tomcat --strip-components=1

cd /opt/tomcat

sudo chgrp -R tomcat conf

sudo chmod g+rwx conf

sudo chmod g+r conf/*

sudo chown -R tomcat work/ temp/ logs/

sudo touch /etc/init/tomcat.conf

#Setup tomcat conf file
sudo sh -c "echo 'description \"Tomcat Server\"
start on runlevel [2345]
stop on runlevel [!2345]
respawn
respawn limit 10 5
setuid tomcat
setgid tomcat
env "\JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/jre"
env "\CATALINA_HOME=/opt/tomcat"
# Modify these options as needed
env "\JAVA_OPTS='"-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom"'"
env "\CATALINA_OPTS='"-Xms512M -Xmx1024M -server -XX:+UseParallelGC"'"
exec "\$CATALINA_HOME"/bin/catalina.sh run
# cleanup temp directory after stop
post-stop script
rm -rf "\$CATALINA_HOME/temp/*"
end script' > /etc/init/tomcat.conf"


#Reload configuration and start tomcat Server
sudo initctl reload-configuration
sudo initctl stop tomcat
sudo initctl start tomcat
