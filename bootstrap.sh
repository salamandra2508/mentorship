#!/bin/bash

set -x


#newname=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

#echo $newname

#new_name=$(sudo hostnamectl set-hostname TEST-$newname)

#echo $newname

tomver="apache-tomcat-8.0.23"



#sudo apt-get update
#sudo apt-get install -y default-jdk wget mc htop
#sudo groupadd tomcat
#sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat
cd ~

if [[ ! -f /home/ubuntu/$tomver.tar.gz ]]; then
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

config=$(sudo touch /etc/init/tomcat.conf)

sudo cat <<EOF > /etc/init/tomcat.conf
description "Tomcat Server"
start on runlevel [2345]
stop on runlevel [!2345]
respawn
respawn limit 10 5
setuid tomcat
setgid tomcat
env JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/jre
env CATALINA_HOME=/opt/tomcat
# Modify these options as needed
env JAVA_OPTS="-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom"
env CATALINA_OPTS="-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

exec $CATALINA_HOME/bin/catalina.sh run

# cleanup temp directory after stop
post-stop script
rm -rf $CATALINA_HOME/temp/*
end script
EOF


sudo initctl reload-configuration
sudo initctl start tomcat
