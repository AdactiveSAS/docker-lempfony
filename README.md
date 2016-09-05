## docker-lempfony

Set up a development environment in a single container.

- Ubuntu 16.04
- Nginx
- MySQL
- PHP 7.0
- phpMyAdmin
- Composer
- Symfony

### Build
<pre><code>docker build \
  --build-arg mysql_root_pwd=<i><b>custom_pwd</b></i> \
  -t naei/lempfony .</code></pre>
If ```--build-arg [...]``` is not set, MySQL credentials will be root:development.

##### ... or directly pull the image from the Docker Hub Registry:
```docker pull naei/lempfony```

### Run 
#### ...in shell
<pre><code>docker run -it -p 80:80 \
  -v <i><b>~/projects/log</b></i>:/var/log \
  -v <i><b>~/projects/mysql</b></i>:/var/lib/mysql \
  -v <i><b>~/projects/www</b></i>:/var/www \
  -v <i><b>~/projects/sites</b></i>:/etc/nginx/sites-available \
  naei/lempfony:latest</code></pre>

#### ...in detached mode
<pre><code>docker run -dit -p 80:80 \
  -v <i><b>~/projects/log</b></i>:/var/log \
  -v <i><b>~/projects/mysql</b></i>:/var/lib/mysql \
  -v <i><b>~/projects/www</b></i>:/var/www \
  -v <i><b>~/projects/sites</b></i>:/etc/nginx/sites-available \
  naei/lempfony:latest</code></pre>

### Create a new Symfony app
To quickly setup a functionnal new Symfony app (development only):
<pre><code>symfony-create <i><b>app-name</b></i> <i><b>[symfony-version]</b></i></code></pre>

### Troubleshooting

#### Windows host: the Symfony project creation crash after "Preparing project..."
The Symfony project creation process works with symlinks. By default on Windows,  only an administrator can create symlink, so be sure that the Docker terminal is launched as an administrator. 

#### Windows host: the local domain names are accessible from inside the container but not from a web browser
Each domain name must be binded to the Docker container's IP in the C:\Windows\System32\drivers\etc\hosts file:
<pre><code>192.168.99.100 project.dev
192.168.99.100 otherproject.dev</code></pre>

