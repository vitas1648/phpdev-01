#!/usr/bin/env bash

#
# Install ZSH
#
sudo apt -y install zsh

#
# Install Oh-my-zsh via curl
# initially install curl
#
sudo apt -y install curl
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

#
# Install mysql php-fpm phpmyadmin
#
sudo apt -y install mysql-server php-fpm phpmyadmin

#
# Create Nginx config for phpmyadmin
#
cat << EOF > pma.conf
server {
    listen              80;
    server_name			pma.my;

    access_log          /var/log/nginx/phpmyadmin.access.log;
    error_log           /var/log/nginx/phpmyadmin.error.log;

    root                /usr/share/phpmyadmin;
    index               index.php;

    charset             utf-8;

    location / {
        if (-f $request_filename) {
            expires max;
            break;
        }
        if ( !-e $request_filename ) {
            rewrite ^(.*) /index.php last;
        }
    }

    location ~ "^(.+\.php)($|/)" {
        fastcgi_split_path_info ^(.+\.php)(.*)$;
        fastcgi_param   SCRIPT_FILENAME   $document_root$fastcgi_script_name;
        fastcgi_param   SCRIPT_NAME       $fastcgi_script_name;
        fastcgi_param   PATH_INFO         $fastcgi_path_info;
        fastcgi_pass    unix:/run/php/php7.4-fpm.sock;
        include         fastcgi_params;
    }
}
EOF
sudo mv pma.conf /etc/nginx/sites-available/pma.conf
sudo ln -sf /etc/nginx/sites-available/pma.conf /etc/nginx/sites-enabled/pma.conf
sudo service nginx restart

#
# Add hosts names to /etc/hosts
#
cp /etc/hosts .
echo "127.0.0.1    nginx.my pma.my" >> hosts
sudo mv -f hosts /etc/hosts

#
# Configure PhpMyAdmin
#
cat << EOF > config.sql
CREATE DATABASE test1;
CRANT ALL PRIVILEGES ON test1.* TO 'phpmyadmin'@'localhost';
UPDATE mysql.user SET plugin = 'mysql_native_password', authentication_string  = '' WHERE user = 'root';
EOF

sudo mkdir -f /www
sudo mv config.sql /www/
sudo mysql -u root < /www/config.sql
sudo systemctl restart mysql.service

#
# Create dump mysql database phpmyadmin
#
mysqldump -u root -h localhost > pma.sql 
sudo mv pma.sql /www/
sudo gzip -k /www/pma.sql /www/pma.sql.gz
size_sql_dump=$(ls -l /www/pma.sql | awk '{ print($5) }')
size_sql_gz_dump=$(ls -l /www/pma.sql.gz | awk '{ print($5) }')
echo "pma.sql: $size_sql_dump pma.sql.gz: $size_sql_gz_dump"

# By one string
# sudo su -c "mysqldump -u root -h localhost -p phpmyadmin > /www/pma.sql; gzip -kf /www/pma.sql /www/pma.sql.gz; ls -l /www/pma.sql{,.gz}" | awk '{ print($5) }'
