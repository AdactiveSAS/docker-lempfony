# docker-lempfony

Set up a development environment in a single container.

Ubuntu 16.04 | Nginx | MySQL | PHP 7.0 | phpMyAdmin | Composer | Symfony  

### Fork

This project is a fork of [naei/docker-lempfony](https://github.com/naei/docker-lempfony).  
It adapt it for the need of Adactive/Signall projects by adding the following components:
- PHP modules: 
  - php7.0-json, php7.0-sqlite3, php7.0-recode, php7.0-imap, php7.0-curl, php-apcu, php-xdebug, php7.0-snmp
- Composer plugins:
  - fxp/composer-asset-plugin
  - sstalle/php7cc
  - bamarni/symfony-console-autocomplete
  - escapestudios/symfony2-coding-standard
- SNMP
- Redis

### Get the image

#### ...by pulling it from the Docker Hub Registry:

```shell
docker pull signall/lempfony
```  

#### ...by building it from the sources:

Clone the project, access it from your terminal, then build it:

```shell
docker build \
  --build-arg mysql_root_pwd=<custom_pwd> \
  -t signall/lempfony .
```  

If ```--build-arg [...]``` is not set, MySQL credentials will be root:development.


### Run the container

```shell
docker run -it --rm --name lempfony -p 80:80 \
  -v <workspace/conf/lempfony>:/etc/opt/lempfony/volume \
  -v <workspace/conf/nginx-sites>:/etc/nginx/sites-available \
  -v <workspace/log>:/var/log \
  -v <workspace/mysql>:/var/lib/mysql \
  -v <workspace/www>:/var/www \
  signall/lempfony:latest
```
For detached mode, replace the first line by:  
```docker run -dit --name lempfony -p 80:80 \```  

The data volumes are optionals and can be added or removed depending on the needs.  

If you need to have commands executed after the services launch, you can create a init.sh script and share it in a data volume within /opt/lempfony/volume, which is a folder dedicated to user-specific files.
For detailled information about it, you can take a look at the [example](https://github.com/naei/docker-lempfony/tree/master/example/workspace) workspace on the upstream repository.


### Create a new Symfony app
From the container shell, you can quickly setup a functionnal new Symfony app:
```shell
symfony-create <app-name> [symfony-version]
```
Your project will be immediately accessible at &lt;app-name>.dev .


### Troubleshooting

#### ➢ I don't know on which IP my container is running
```shell
docker inspect --format '{{ .NetworkSettings.IPAddress }}' lempfony
```  

#### ➢ The local domain name is not accessible from Firefox
You might need to add the local domain name into about:config > network.dns.localDomains

#### ➢ Windows host: the Symfony project creation script crash after "Preparing project..."
The Symfony project creation process works with symlinks. By default on Windows,  only an administrator can create symlink, so be sure that the Docker terminal is launched as an administrator. 

#### ➢ Windows host: the local domain names are accessible from inside the container but not from a web browser
Each domain name must be binded to the Docker container's IP in the C:\Windows\System32\drivers\etc\hosts file:
```
192.168.99.100 project.dev
192.168.99.100 otherproject.dev
```  
