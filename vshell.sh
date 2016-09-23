#! /bin/bash

clear
echo ' '
echo '###########################'
echo '###### SETTING UP VM ######'
echo '###########################'
echo ' '
# Project Variables
SERVERINFO='ServerName localhost'
PROJECTNAME='microwebsite'
APPENV=local
DBHOST=localhost
DBNAME=dev_micro_database_test
DBUSER=root
PASSWORD=root



echo ' '
echo '###########################'
echo '###### UPDATE UBUNTU ######'
echo '###########################'
echo ' '
sudo apt-get update 
sudo apt-get -y upgrade



echo ' '
echo '###########################'
echo '######### APACHE2 #########'
echo '###########################'
echo ' '
sudo apt-get -y install apache2
echo "${SERVERINFO}" >> /etc/apache2/apache2.conf
sudo mkdir -p /var/www/"${PROJECTNAME}"/web
WEBFILE=$(cat <<EOF
<html>
 <head>
  <title>${PROJECTNAME}</title>
 </head>
 <body>
  <h3>${PROJECTNAME}</h3>
 </body>
</html>
EOF
)
echo "${WEBFILE}" > /var/www/"${PROJECTNAME}"/web/index.php
sudo service apache2 restart
VHOST1=$(cat <<EOF
<VirtualHost *:80>
    ServerName "${PROJECTNAME}.local"
    ServerAlias "www.${PROJECTNAME}.local"
    DocumentRoot "/var/www/${PROJECTNAME}/web"
    <Directory "/var/www/${PROJECTNAME}/web">
        Options +FollowSymlinks +Indexes +Includes +MultiViews
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
)
echo "${VHOST1}" > /etc/apache2/sites-available/001-"${PROJECTNAME}".conf
sudo a2dissite 000-default.conf
sudo a2ensite 001-"${PROJECTNAME}".conf
sudo a2enmod rewrite
sudo service apache2 restart



echo ' '
echo '###########################'
echo '########### PHP ###########'
echo '###########################'
echo ' '
sudo apt-get -y install php5
sudo service apache2 restart



echo ' '
echo '###########################'
echo '########## MYSQL ##########'
echo '###########################'
echo ' '
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
sudo apt-get -y install mysql-client-5.5 mysql-common mysql-server mysql-server-5.5 php5-common php5-mysql
#mysql -uroot -p$PASSWORD -e "CREATE DATABASE $DBNAME"
#mysql -uroot -p$PASSWORD -e "grant all privileges on $DBNAME.* to '$DBUSER'@'localhost' identified by '$PASSWORD'"
sudo service apache2 restart



echo ' '
echo '###########################'
echo '########### GIT ###########'
echo '###########################'
echo ' '
sudo apt-get -y install git



echo ' '
echo '###########################'
echo '####### GETCOMPOSER #######'
echo '###########################'
echo ' '
curl -s https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer



echo ' '
echo '###########################'
echo '#### PROCESS COMPLETED ####'
echo '###########################'
echo ' '

# create tmp directory
sudo mkdir -p /vagrant/"${PROJECTNAME}"/web

# mv website to backup
sudo mv /var/www/"${PROJECTNAME}" /var/www/"${PROJECTNAME}"_old

# make a symbolic link to new structure
sudo ln -s /vagrant/"${PROJECTNAME}" /var/www/"${PROJECTNAME}"

MICROSITEFILE=$(cat <<EOF
<?php

require_once __DIR__.'/../vendor/autoload.php';

\$app = new Silex\Application();

\$app->get('/', function () { return 'Base Page Loaded!'; });

\$app['debug'] = true;

\$app->run();

EOF
)
echo "${MICROSITEFILE}" > /vagrant/"${PROJECTNAME}"/web/index.php

JSON=$(cat <<EOF
{
    "require": {
        "silex/silex": "2.0"
    }
}
EOF
)
echo "${JSON}" > /vagrant/"${PROJECTNAME}"/composer.json

SETUP=$(cat <<EOF
#!/bin/bash
cd /vagrant/"${PROJECTNAME}"
composer install
EOF
)
echo "${SETUP}" > setup.sh
chmod +x setup.sh

if [ -f "/vagrant/${PROJECTNAME}/composer.lock" ] 
then
    echo ' '
    echo '############################'
    echo '## MICROSERVICE INSTALLED ##'
    echo '############################'
    echo ' '
else
    echo ' '
    echo '##########################'
    echo '### SETUP MICROSERVICE ###'
    echo '##########################'
    echo ' '
    source setup.sh
fi

echo ' '
echo '###########################'
echo '####### PLEASE READ #######'
echo '###########################'
echo ' '
echo '### To log into the VM type "vagrant ssh". ###'
echo ' '
echo 'PLEASE WAIT UNTIL THE "composer.lock" APPEARS BEFORE USING THE APP'
echo ' '

