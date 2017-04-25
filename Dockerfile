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
  apt-get install -y software-properties-common python-software-properties && \
  add-apt-repository -y ppa:thomas-schiex/blender && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y acl curl git nano vim wget htop realpath mysql-client build-essential tcl && \
# NGINX
  apt-get install -y nginx && \
# PHP 7.0
  apt-get install -y php7.0-fpm php7.0-cli php7.0-intl php7.0-xml php7.0-mysql php7.0-zip php7.0-gd php7.0-tidy php7.0-json php7.0-sqlite3 php7.0-recode php7.0-imap php7.0-curl php-apcu php7.0-xsl php-xdebug && \
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
  apt-get install -y redis-server redis-tools && \
# SNMP
  apt-get install -y snmp php7.0-snmp && \
# NodeJs
  apt-get install -y nodejs && \
# Blender
  apt-get install -y blender && \
# s3cm
  apt-get install -y s3cmd && \
# CAPISTRANO
  apt-get install -y ant capistrano && \
  gem install capistrano -v 3.4.0 && \
  gem install capistrano-symfony && \
  gem install capistrano-maintenance && \
  gem install capistrano-nginx

# copy system files - all the files contained in the "conf" folder will be copied to the system keeping the same folder hierarchy
#   > /etc/nginx/default/site-default >> default server block configuration - will be copied back into /etc/nginx/sites-available/ at run
#   > /etc/php/* >> php configuration files
#   > /usr/bin/symfony-create >> Symfony project creation script
#   > /root/* >> user bash configs (for XDebug, Symfony, Composer...)
COPY conf /

ADD https://github.com/AdactiveSAS/osg/releases/download/OpenSceneGraph-3.3.3-ADACTIVE/osg.tar.gz /tmp/osg.tar.gz

# configure environment & finalize installation
RUN \
# OpenSceneGraph
  cd /tmp && tar -xvzf osg.tar.gz && chmod +x osg/bin/* osg/lib/* && \
  cp -R osg/bin/* /usr/local/bin && cp -R osg/lib/* /usr/local/lib && ldconfig && \
# Create databases
  service mysql start && \
  mysqladmin -u root -p$mysql_root_pwd create adsum && \
  mysqladmin -u root -p$mysql_root_pwd create adsum-recovery && \
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
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  mkdir -p /var/log/redis && chown redis:redis /var/log/redis

RUN \
  usermod -a -G redis www-data && \
  usermod -a -G redis ubuntu && \
  usermod -a -G www-data ubuntu

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
  cp -f /etc/php/7.0/fpm/default/www.conf /etc/php/7.0/fpm/pool.d/www.conf && \
  cp -f /etc/nginx/default/site-default /etc/nginx/sites-available/default && \
  ln -sf /etc/nginx/sites-available/* /etc/nginx/sites-enabled/ && \
  # restore permissions on workspace and logs
  chmod 1777 /tmp && \
  mkdir -p /var/log/nginx && chown -R www-data /var/log/nginx && \
  mkdir -p /var/log/mysql && chown -R mysql /var/log/mysql && \
  # restore lempfony init script if none exists
  cp -n /opt/lempfony/default/init.sh /opt/lempfony/volume/init.sh && \
  chmod +x /opt/lempfony/volume/init.sh && sync && \
# start services
  service mysql start && \
  service php7.0-fpm start && \
  service nginx start && \
  service redis-server start && \
  /bin/bash -c "source ~/.profile" && \
# execute lempfony init script in a subshell
  echo " * Executing user-specific configuration" && \
  (cd /opt/lempfony/volume && ./init.sh) && \
# run bash
  echo && \
  /bin/bash