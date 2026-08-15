# Inception — Mandatory Part: Full Steps

Login placeholder: `login` -> replace everywhere with your 42 username.

## 1. Directory Structure

```
.
├── Makefile
├── secrets/
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── docker-compose.yml
    ├── .env
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        └── mariadb/
            ├── Dockerfile
            ├── conf/
            └── tools/
```

## 2. VM Setup

- Install/verify Docker + docker-compose on VM.
- Edit `/etc/hosts` (or VM's hosts) -> add: `127.0.0.1 login.42.fr`

## 3. .env File (srcs/.env)

```
DOMAIN_NAME=login.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
WP_ADMIN_USER=my_super_admin   # NOT "admin"
WP_ADMIN_EMAIL=admin@login.42.fr
WP_USER=second_user
WP_USER_EMAIL=user@login.42.fr
```
! No passwords here. Passwords -> secrets/ files.

## 4. secrets/ Files

- `db_password.txt` -> WP DB user password
- `db_root_password.txt` -> MariaDB root password
- `credentials.txt` -> WP admin password (+ second user password)

Reference in docker-compose via `secrets:` block, read inside containers as `_FILE` env vars or via `/run/secrets/<name>`.

## 5. Network

docker-compose.yml top level:
```yaml
networks:
  inception:
    driver: bridge
```
Each service -> `networks: [inception]`. No `network: host`, no `--link`, no `links:`.

## 6. Volumes

```yaml
volumes:
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      device: /home/login/data/wordpress
      o: bind
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      device: /home/login/data/mariadb
      o: bind
```
Named volumes only. No raw bind mounts. Create host dirs first: `mkdir -p /home/login/data/{wordpress,mariadb}`.

## 7. MariaDB Container

Dockerfile (Alpine/Debian penultimate stable):
- Install mariadb server.
- Copy custom `conf/my.cnf` (bind-address 0.0.0.0, skip default socket-only config).
- Copy entrypoint script -> init DB on first run:
  - Start mysqld_safe temporarily.
  - Create `wordpress` DB.
  - Create WP user + grant privileges (password from secret).
  - Set root password (from secret).
  - Stop temp instance.
- CMD -> `exec mysqld_safe` (or `mariadbd`) as PID 1, foreground. No `tail -f`, no infinite loop hacks.

## 8. WordPress + php-fpm Container

Dockerfile:
- Install php-fpm, php-mysqli, curl, wget (for wp-cli).
- Install WP-CLI.
- Copy entrypoint script -> on container start:
  - Wait for MariaDB reachable (retry loop with timeout, not infinite blocking).
  - `wp core download` if not present (volume empty).
  - `wp config create` using .env vars + DB password secret.
  - `wp core install` -> creates admin user (username != admin/administrator variants) + second regular user.
  - Configure php-fpm to listen on 0.0.0.0:9000 (not localhost only).
- CMD -> `exec php-fpm81 -F` (foreground, PID 1). No nginx inside this container.

## 9. NGINX Container

Dockerfile:
- Install nginx.
- Generate self-signed TLS cert (openssl) at build or via entrypoint, using DOMAIN_NAME.
- Copy nginx.conf -> configure:
  - `listen 443 ssl;`
  - `ssl_protocols TLSv1.2 TLSv1.3;`
  - `server_name login.42.fr;`
  - `fastcgi_pass wordpress:9000;`
- CMD -> `exec nginx -g "daemon off;"` (PID 1 foreground).

## 10. Restart Policy

Every service in docker-compose.yml:
```yaml
restart: on-failure
```
(or `always` / `unless-stopped` — must restart on crash).

## 11. docker-compose.yml Skeleton

```yaml
services:
  mariadb:
    build: ./requirements/mariadb
    image: mariadb
    container_name: mariadb
    env_file: .env
    secrets: [db_password, db_root_password]
    volumes: [mariadb_data:/var/lib/mysql]
    networks: [inception]
    restart: on-failure

  wordpress:
    build: ./requirements/wordpress
    image: wordpress
    container_name: wordpress
    env_file: .env
    secrets: [db_password, credentials]
    volumes: [wordpress_data:/var/www/html]
    depends_on: [mariadb]
    networks: [inception]
    restart: on-failure

  nginx:
    build: ./requirements/nginx
    image: nginx
    container_name: nginx
    env_file: .env
    volumes: [wordpress_data:/var/www/html]
    ports: ["443:443"]
    depends_on: [wordpress]
    networks: [inception]
    restart: on-failure

volumes:
  wordpress_data: {...}
  mariadb_data: {...}

networks:
  inception: {...}

secrets:
  db_password:
    file: ../secrets/db_password.txt
  db_root_password:
    file: ../secrets/db_root_password.txt
  credentials:
    file: ../secrets/credentials.txt
```

## 12. Makefile

```makefile
all:
	mkdir -p /home/login/data/wordpress /home/login/data/mariadb
	docker-compose -f srcs/docker-compose.yml up -d --build

down:
	docker-compose -f srcs/docker-compose.yml down

clean: down
	docker system prune -af

fclean: clean
	sudo rm -rf /home/login/data/wordpress/* /home/login/data/mariadb/*

re: fclean all

.PHONY: all down clean fclean re
```

## 13. Build & Test

```
make
docker ps                     # 3 containers, all "Up"
docker network ls | grep inception
docker volume ls | grep -E "wordpress|mariadb"
```
Browser -> `https://login.42.fr` -> WP site loads, TLS padlock valid.
`https://login.42.fr/wp-admin` -> log in as admin user (non-"admin" username).

## 14. Checks Before Defense

- [ ] No `latest` tag anywhere.
- [ ] No hardcoded passwords in Dockerfiles/compose/code.
- [ ] `.env` git-ignored if it contains sensitive data; secrets/ git-ignored.
- [ ] Each Dockerfile PID 1 = actual service process, no `tail -f`/`sleep infinity`/`while true`.
- [ ] Two WP users, admin username has no "admin"/"administrator" substring.
- [ ] Restart-on-crash confirmed (`docker kill <container>` -> auto-restarts).
- [ ] Volumes survive `docker-compose down && up` (data persists in /home/login/data).
- [ ] Only port 443 exposed; nginx is sole entrypoint.

## 14b. Deep-Dive Per Service (build steps + study links)

### NGINX

Build steps:
1. `FROM debian:bookworm-slim` (or alpine:3.20 — check current penultimate stable).
2. `RUN apt update && apt install -y nginx openssl`.
3. Generate self-signed cert in Dockerfile or entrypoint:
   `openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/login.42.fr.key -out /etc/nginx/ssl/login.42.fr.crt -subj "/CN=login.42.fr"`
4. `COPY conf/nginx.conf /etc/nginx/nginx.conf` (or a site conf in `sites-available`).
5. `EXPOSE 443`.
6. `CMD ["nginx", "-g", "daemon off;"]`.

Reverse proxy to WordPress (php-fpm) — nginx does not "proxy" PHP like HTTP, it uses FastCGI:
```nginx
server {
    listen 443 ssl;
    server_name login.42.fr;
    ssl_certificate     /etc/nginx/ssl/login.42.fr.crt;
    ssl_certificate_key /etc/nginx/ssl/login.42.fr.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    root /var/www/html;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```
`wordpress:9000` resolves via Docker's internal DNS (service name = container hostname on the `inception` network).

Load balancing (not required by subject, but if you want to study it): nginx `upstream` block with multiple php-fpm replicas —
```nginx
upstream php_backend {
    server wordpress1:9000;
    server wordpress2:9000;
}
```
then `fastcgi_pass php_backend;`. Docker Compose `deploy.replicas` (Swarm) or multiple named services simulate this.

Study links:
- https://nginx.org/en/docs/
- https://nginx.org/en/docs/http/ngx_http_fastcgi_module.html
- https://nginx.org/en/docs/http/configuring_https_servers.html
- https://docs.docker.com/engine/reference/builder/ (Dockerfile ref)
- https://www.digitalocean.com/community/tutorials/understanding-nginx-http-proxying-load-balancing-buffering-and-caching

### WordPress + php-fpm

Build steps:
1. Base image + `RUN apt install -y php-fpm php-mysqli curl wget default-mysql-client`.
2. Install WP-CLI:
   `curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp`
3. Edit `www.conf` (php-fpm pool) -> `listen = 9000` and `listen.allowed_clients` removed/adjusted so nginx container can reach it (php-fpm listens on all interfaces inside its own container, reachable by service name over the Docker network — no need to expose ports host-side).
4. Entrypoint script logic:
   - `wait-for-it` style loop pinging mariadb:3306 before proceeding.
   - If `/var/www/html/wp-config.php` absent: `wp core download`, `wp config create --dbname=... --dbuser=... --dbpass=$(cat /run/secrets/db_password) --dbhost=mariadb`.
   - `wp core install --url=... --title=... --admin_user=$WP_ADMIN_USER --admin_password=$(cat /run/secrets/credentials) --admin_email=...`
   - `wp user create $WP_USER $WP_USER_EMAIL --role=author --user_pass=...` (second user).
5. `CMD ["php-fpm8.2", "-F"]` (foreground = PID 1 correctness).

Study links:
- https://wordpress.org/documentation/article/installing-wordpress-with-wp-cli/
- https://make.wordpress.org/cli/handbook/
- https://www.php.net/manual/en/install.fpm.php
- https://www.php.net/manual/en/install.fpm.configuration.php (pool conf, `listen`, `pm` settings)
- https://developer.wordpress.org/cli/commands/config/create/

### MariaDB

Build steps:
1. `RUN apt install -y mariadb-server`.
2. `COPY conf/my.cnf /etc/mysql/mariadb.conf.d/50-server.cnf` -> set `bind-address = 0.0.0.0` (default is 127.0.0.1, must open for container-to-container access).
3. Entrypoint script:
   - `mysql_install_db` if data dir empty.
   - Start `mariadbd` temporarily in background (`--skip-networking` optional for init phase).
   - `mysql -e "CREATE DATABASE IF NOT EXISTS wordpress;"`
   - `mysql -e "CREATE USER 'wp_user'@'%' IDENTIFIED BY '$(cat /run/secrets/db_password)';"`
   - `mysql -e "GRANT ALL ON wordpress.* TO 'wp_user'@'%';"`
   - `mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$(cat /run/secrets/db_root_password)';"`
   - Shut temp instance down cleanly.
4. `CMD ["mariadbd"]` or `CMD ["mysqld_safe"]` -> foreground, PID 1.

Study links:
- https://mariadb.com/kb/en/documentation/
- https://mariadb.com/kb/en/configuring-mariadb-with-option-files/
- https://mariadb.com/kb/en/mysql_install_db/
- https://mariadb.com/kb/en/grant/
- https://docs.docker.com/engine/reference/builder/#entrypoint (init-then-exec pattern)

### General Docker / Compose references

- https://docs.docker.com/compose/compose-file/
- https://docs.docker.com/engine/reference/builder/
- https://docs.docker.com/engine/storage/volumes/
- https://docs.docker.com/compose/use-secrets/
- https://docs.docker.com/engine/network/drivers/bridge/
- https://12factor.net/ (config via env, useful conceptual backing for .env/secrets split)

## 15. README.md (repo root)

Must start (italic):
`*This project has been created as part of the 42 curriculum by <login>.*`

Sections required: Description, Instructions, Resources (+ AI usage disclosure), Project description (VM vs Docker, Secrets vs Env vars, Docker network vs host, Volumes vs bind mounts).

Also required at repo root: `USER_DOC.md`, `DEV_DOC.md` (see subject Ch. VII for exact content).