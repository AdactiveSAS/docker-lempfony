FROM ubuntu:16.04
MAINTAINER Lucas Pantanella

# skip "apt-get install" interactive prompts during build
ARG DEBIAN_FRONTEND=noninteractive

# a default MySQL root password can be set at build
# otherwise, the password "development" will be used
ARG mysql_root_pwd=development

# Install system
RUN \
# update system & install essential packages
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y acl curl git nano vim wget && \
# NGINX
  apt-get install -y nginx && \
# PHP 7.0
  apt-get install -y php7.0-fpm php7.0-cli php7.0-intl php7.0-xml php7.0-mysql php7.0-zip php7.0-gd php7.0-tidy php7.0-json php7.0-sqlite3 php7.0-recode php7.0-imap php7.0-curl php-apcu php-xdebug && \
  echo "<?php phpinfo(); ?>" > /var/www/index.php && \
# COMPOSER
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
# SYMFONY
  curl -LsS https://symfony.com/installer -o /usr/local/bin/symfony && \
  chmod a+x /usr/local/bin/symfony && \
# MYSQL
  apt-get install -y mysql-server && \
  usermod -d /var/lib/mysql/ mysql && \
  service mysql start && mysqladmin -u root password $mysql_root_pwd && \
# PHPMYADMIN
  apt-get install -y phpmyadmin && \
# REDIS
  apt-get install -y redis-server && \
# SNMP
  apt-get install -y snmp php7.0-snmp

# copy system files - all the files contained in the "conf" folder will be copied to the system keeping the same folder hierarchy
#   > /etc/nginx/default/site-default >> default server block configuration - will be copied back into /etc/nginx/sites-available/ at run
#   > /etc/php/* >> php configuration files
#   > /usr/bin/symfony-create >> Symfony project creation script
#   > /root/* >> user bash configs (for XDebug, Symfony, Composer...)
COPY conf /

# configure environment & finalize installation
RUN \
# backup default MySQL & phpMyAdmin databases to save these data from shared volume - will be copied back into /var/lib/mysql/ at run
  service mysql stop && \
  mkdir /var/lib/mysql-db && \
  mv /var/lib/mysql/* /var/lib/mysql-db/ && \
# give execution rights to the Symfony project creation script
  chmod a+x /usr/bin/symfony-create && \
# create a lempfony directory dedicated to user-specific files
  mkdir -p /opt/lempfony/default /opt/lempfony/volume && \
  # add a default init.sh script - will be copied to /opt/lempfony/volume and executed on container start
  echo "#!/bin/bash" \
    "\n\n# This script is executed on container start." \
    "\n\necho \"   ...no commands specified\"" \
    > /opt/lempfony/default/init.sh && \
# disable XDebug
  rm /etc/php/7.0/cli/conf.d/20-xdebug.ini && \
# update composer dependencies
  composer global update && \
# clean system
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /var/www

EXPOSE 80 443

# configure the container on 'docker run'
ENTRYPOINT \
  echo " ###################################" && \
  echo " ###       docker-lempfony       ###" && \
  echo " ###################################" && \
  echo && \
# handle data volumes
  # restore default MySQL database and permissions
  cp -rn /var/lib/mysql-db/* /var/lib/mysql && \
  chown -R mysql /var/lib/mysql && \
  # restore default Nginx server block and enable all sites
  cp -f /etc/nginx/default/site-default /etc/nginx/sites-available/default && \
  ln -sf /etc/nginx/sites-available/* /etc/nginx/sites-enabled/ && \
  # restore permissions on workspace and logs
  chown -R www-data /var/www && \
  mkdir -p /var/log/nginx && chown -R www-data /var/log/nginx && \
  mkdir -p /var/log/mysql && chown -R mysql /var/log/mysql && \
  # restore lempfony init script if none exists
  cp -n /opt/lempfony/default/init.sh /opt/lempfony/volume/init.sh && \
  chmod +x /opt/lempfony/volume/init.sh && sync && \
# start services
  service mysql start && \
  service php7.0-fpm start && \
  service nginx start && \
  /bin/bash -c "source ~/.profile" && \
# execute lempfony init script in a subshell
  echo " * Executing user-specific configuration" && \
  (cd /opt/lempfony/volume && ./init.sh) && \
# run bash
  echo && \
  /bin/bash