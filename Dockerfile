FROM ubuntu:16.04
MAINTAINER Lucas Pantanella

# Skip "apt-get install" interactive prompts during build
ARG DEBIAN_FRONTEND=noninteractive

# A default MySQL root password can be set at build
# Otherwise, the password "development" will be used
ARG mysql_root_pwd=development

# Add Symfony project creation script
COPY symfony-create.sh /usr/bin/symfony-create

RUN \
# Update system & install essential packages
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y acl curl git nano vim wget && \
# Install Nginx
  apt-get install -y nginx && \
# Install PHP 7.0
  apt-get install -y php7.0-fpm php7.0-cli php7.0-intl php7.0-xml php7.0-mysql php7.0-zip php7.0-gd php7.0-tidy php7.0-json php7.0-sqlite3 php7.0-recode php7.0-imap php7.0-curl php-apcu php-xdebug && \
  sed -i \
    -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" \
    -e "s/;date.timezone.*$/date.timezone = \"UTC\"/" \
    /etc/php/7.0/fpm/php.ini && \
  sed -i "s/;date.timezone.*$/date.timezone = \"UTC\"/" /etc/php/7.0/cli/php.ini && \
  echo "<?php phpinfo(); ?>" > /var/www/index.php && \
  printf "alias phpXdebug='php -dzend_extension=xdebug.so -dxdebug.remote_enable=1 -dxdebug.remote_autostart=On -dxdebug.idekey=PHPSTORM -dxdebug.remote_host=127.0.0.1 -dxdebug.remote_port=9009'%s\nalias phpunit='phpXdebug $(which phpunit)'" >> ~/.bash_aliases && \
# Install Composer
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
# Install Symfony
  curl -LsS https://symfony.com/installer -o /usr/local/bin/symfony && \
  chmod a+x /usr/local/bin/symfony /usr/bin/symfony-create && \
  composer global require bamarni/symfony-console-autocomplete && \
  echo 'eval "$(symfony-autocomplete)"' >> ~/.bash_profile  && \
# Install MySQL
  apt-get install -y mysql-server && \
  usermod -d /var/lib/mysql/ mysql && \
  service mysql start && mysqladmin -u root password $mysql_root_pwd && \
# Install phpMyAdmin
  apt-get install -y phpmyadmin && \
# Install Redis
  apt-get install -y redis-server && \
# Install SNMP
  apt-get install -y snmp php7.0-snmp && \
# Move default MySQL & phpMyAdmin databases to a non-shared folder
# ...which will be copied back into /var/lib/mysql/ at run
  service mysql stop && \
  mkdir /var/lib/mysql-db && \
  mv /var/lib/mysql/* /var/lib/mysql-db/ && \
# Clean system
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add default Nginx server block for PHP and phpMyAdmin to a non-shared folder
# ...which will be copied back into /etc/nginx/sites-available/ at run
COPY site-default /etc/nginx/site-default

WORKDIR /var/www

EXPOSE 80

ENTRYPOINT \
# Actions on shared volumes
  # Restore default MySQL & phpMyAdmin databases
  cp -rn /var/lib/mysql-db/* /var/lib/mysql && \
  # Restore and enable Nginx server blocks
  cp -f /etc/nginx/site-default /etc/nginx/sites-available/default && \
  ln -sf /etc/nginx/sites-available/* /etc/nginx/sites-enabled/ && \
  # Set permissions
  chown -R mysql /var/lib/mysql && \
  mkdir -p /var/log/mysql && chown -R mysql /var/log/mysql && \
  chown -R www-data /var/www && \
  mkdir -p /var/log/nginx && chown -R www-data /var/log/nginx && \
# Start services
  service mysql start && \
  service php7.0-fpm start && \
  service nginx start && \
  service redis-server start && \
  /bin/bash