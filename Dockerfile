FROM ubuntu:16.04
MAINTAINER Lucas Pantanella

# Skip "apt-get install" interactive prompts during build
ARG DEBIAN_FRONTEND=noninteractive

# A default MySQL root password can be set at build
# Otherwise, the password "development" will be used
ARG mysql_root_pwd=development

# Add Symfony project creation script
COPY symfony-create.sh /usr/bin/symfony-create

# Update system & install essential packages
RUN apt-get update && apt-get -y upgrade 

## Install essential packages
RUN apt-get update && apt-get install -y acl curl git nano vim wget sudo

# Install Nginx
RUN apt-get update && apt-get install -y nginx

# Add default Nginx server block for PHP and phpMyAdmin to a non-shared folder
# ...which will be copied back into /etc/nginx/sites-available/ at run
COPY site-default /etc/nginx/site-default

# Install PHP 7.0
RUN apt-get update && apt-get install -y php7.0-fpm php7.0-cli php7.0-intl php7.0-xml php7.0-mysql php7.0-zip php7.0-gd php7.0-tidy php7.0-json php7.0-sqlite3 php7.0-recode php7.0-imap php7.0-curl php-apcu php-xdebug

# Install MySQL
RUN apt-get update && apt-get install -y mysql-server
RUN usermod -d /var/lib/mysql/ mysql && service mysql start && mysqladmin -u root password $mysql_root_pwd

# Install phpMyAdmin
RUN apt-get update && apt-get install -y phpmyadmin

# Move default MySQL & phpMyAdmin databases to a non-shared folder
# ...which will be copied back into /var/lib/mysql/ at run
RUN service mysql stop
RUN mkdir /var/lib/mysql-db
RUN mv /var/lib/mysql/* /var/lib/mysql-db/ 

# Install Redis
RUN apt-get update && apt-get install -y redis-server

# Install SNMP
RUN apt-get update && apt-get install -y snmp php7.0-snmp 

# Configure PHP-CLI
COPY config/php/conf.d/cli.ini /etc/php/7.0/cli/conf.d/10-cli.ini
RUN rm /etc/php/7.0/cli/conf.d/20-xdebug.ini

# Configure PHP-FPM
COPY config/php/conf.d/fpm.ini /etc/php/7.0/fpm/conf.d/10-fpm.ini

# Configure NGINX
## TODO ##

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
 
# Install Symfony Installer
RUN curl -LsS https://symfony.com/installer -o /usr/local/bin/symfony
RUN chmod a+x /usr/local/bin/symfony /usr/bin/symfony-create

# Clean system
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create ubuntu user
RUN adduser --ingroup www-data --disabled-password --gecos "Ubuntu" ubuntu && \
 echo "ubuntu:www-data" | chpasswd && adduser ubuntu sudo

RUN chown -R mysql /var/lib/mysql && \
  mkdir -p /var/log/mysql && chown -R mysql /var/log/mysql && \
  chown -R www-data:www-data /var/www && \
  mkdir -p /var/log/nginx && chown -R www-data:www-data /var/log/nginx && \
  chmod -R g+rwx /var/www

COPY config/ubuntu /etc/sudoers.d/ubuntu

USER ubuntu

# Install Global composer
RUN mkdir ~/.composer
COPY config/composer.json /home/ubuntu/.composer/composer.json
RUN composer global update

# Configure Bash
ADD config/.bash_profile /home/ubuntu/
ADD config/.bash_aliases /home/ubuntu/

USER root
RUN chmod 0440 /etc/sudoers.d/ubuntu
USER ubuntu

WORKDIR /var/www

EXPOSE 80 443

USER root
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
  chown -R www-data:www-data /var/www && \
  mkdir -p /var/log/nginx && chown -R www-data:www-data /var/log/nginx && \
  chmod -R g+rwx /var/www && \
# Start services
  service mysql start && \
  service php7.0-fpm start && \
  service nginx start && \
  service redis-server start
  
USER ubuntu
ENTRYPOINT /bin/bash
 
# source /home/ubuntu/.profile
