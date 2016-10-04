sudo apt-get update
#Install apache2
sudo apt-get install -y apache2

#Install mysql
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password password'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password password'
sudo apt-get -y install mysql-server mysql-client


#Create database
sudo mysql -uroot -ppassword -e "CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"

#Create the user
sudo mysql -uroot -ppassword -e "GRANT ALL ON wordpress.* TO 'wordpressuser'@'localhost' IDENTIFIED BY 'password';"

#flush privileges and exit
sudo mysql -uroot -ppassword -e "FLUSH PRIVILEGES;"

#Install php modules
sudo apt-get install -y php7.0 php-curl php-gd php-mbstring php-mcrypt php-xml php-xmlrpc php-mysql

#Install apache2-php module
sudo apt-get install libapache2-mod-php7.0 

#Allow override in apache2.conf
echo -e "<Directory /var/www/html/>\n\tAllowOverride All\n</Directory>\n" >> /etc/apache2/apache2.conf

#Enable the rewrite mod then restart
sudo a2enmod rewrite
sudo systemctl restart apache2

#Download and extract wordpress
cd /tmp
curl -L -O --silent https://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz

#Create and .htcaccess file for wordpress
touch /tmp/wordpress/.htaccess
sudo chmod 660 /tmp/wordpress/.htaccess

#Copy over a sample configuration
touch /tmp/wordpress/wp-config.php

#Create an upgrade directory so that permission issues dont pop during updates
mkdir /tmp/wordpress/wp-content/upgrade

#Copy contents of directory into /var/www/html
sudo cp -a /tmp/wordpress/. /var/www/html

#Change permissions
sudo chmod g+w /var/www/html/wp-content
sudo chmod -R g+w /var/www/html/wp-content/themes
sudo chmod -R g+w /var/www/html/wp-content/plugins

#Add the database configuration
sudo touch /var/www/html/wp-config.php
echo -e "<?php\n
define('DB_NAME', 'wordpress');\n
define('DB_USER', 'wordpressuser');\n
define('DB_PASSWORD', 'password');\n
define('DB_HOST', 'localhost');\n
define('DB_CHARSET', 'utf8');\n
define('DB_COLLATE', '');\n

"'$'"table_prefix  = 'wp_';\n

define('WP_DEBUG', false);\n

if ( !defined('ABSPATH') )\n\t
        define('ABSPATH', dirname(__FILE__) . '/');\n

require_once(ABSPATH . 'wp-settings.php');\n" | sudo tee -a /var/www/html/wp-config.php

#Change permissions
sudo chown -R www-data: /var/www/html

#Restart server
sudo systemctl restart apache2
