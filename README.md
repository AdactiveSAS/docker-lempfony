## docker-lempfony

Set up a development environment in a single container.

- Ubuntu 16.04
- Nginx
- MySQL
- PHP 7.0
- phpMyAdmin
- Composer
- Symfony

### Fork

Add the following tools:

- PHP modules: php7.0-json, php7.0-sqlite3, php7.0-recode, php7.0-imap, php7.0-curl, php-apcu, php-xdebug, php7.0-snmp
- Composer / Symfony: bamarni/symfony-console-autocomplete
- SNMP
- Redis

To do :

- Redis: handle database volume
- Nginx: handle SSL

### Build
<pre><code>docker build \
  --build-arg mysql_root_pwd=<i><b>custom_pwd</b></i> \
  -t adactive/lempfony .</code></pre>
If ```--build-arg [...]``` is not set, MySQL credentials will be root:development.

### Run 
#### ...in shell
<pre><code>docker run -it -p 80:80 \
  -v <i><b>~/projects/log</b></i>:/var/log \
  -v <i><b>~/projects/mysql</b></i>:/var/lib/mysql \
  -v <i><b>~/projects/www</b></i>:/var/www \
  -v <i><b>~/projects/sites</b></i>:/etc/nginx/sites-available \
  adactive/lempfony:latest</code></pre>

#### ...in detached mode
<pre><code>docker run -dit -p 80:80 \
  -v <i><b>~/projects/log</b></i>:/var/log \
  -v <i><b>~/projects/mysql</b></i>:/var/lib/mysql \
  -v <i><b>~/projects/www</b></i>:/var/www \
  -v <i><b>~/projects/sites</b></i>:/etc/nginx/sites-available \
  adactive/lempfony:latest</code></pre>

If you need have commands executed after the services launch, you can add the files docker-init.sh and docker-init.conf into a volume:
<pre><code>-v <i><b>~/projects/my_project/conf/docker-init/</b></i>:/opt/docker/ \</code></pre>
Take a look [here](conf/opt/docker/) for more informations.

### Create a new Symfony app
To quickly setup a functionnal new Symfony app (development only):
<pre><code>symfony-create <i><b>app-name</b></i> <i><b>[symfony-version]</b></i></code></pre>

### Troubleshooting

#### Windows host: on which IP the server is running?
<pre><code>docker inspect --format '{{ .NetworkSettings.IPAddress }}' <i><b>container_name_or_id</b></i> </code></pre>

#### Windows host: the Symfony project creation crash after "Preparing project..."
The Symfony project creation process works with symlinks. By default on Windows,  only an administrator can create symlink, so be sure that the Docker terminal is launched as an administrator. 

#### Windows host: the local domain names are accessible from inside the container but not from a web browser
Each domain name must be binded to the Docker container's IP in the C:\Windows\System32\drivers\etc\hosts file:
<pre><code>192.168.99.100 project.dev
192.168.99.100 otherproject.dev</code></pre>

