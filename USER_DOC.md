# User Documentation — Inception

Guide for running and using the deployed stack. Not for internal build details (see DEV_DOC.md).

## What this is

Dockerized WordPress site. Reverse-proxied through NGINX, backed by MariaDB, cached with Redis. Extra tools: FTP access, static page, DB admin UI, container metrics, uptime monitoring.

## Requirements

- Docker + Docker Compose
- Linux VM or host
- Ports free: 443, 21, 21100-21110, 8080, 8081, 8082, 3001

## Setup

1. Add to `/etc/hosts`:
```
127.0.0.1 login.42.fr {in my case jbahmida.42.fr}
```
2. Fill secrets in `secrets/`:
   - `db_password.txt`
   - `db_root_password.txt`
   - `credentials.txt`
   - `ftp_password.txt`
3. Run:
```bash
make all
```
Creates data directories, builds images, starts stack.

## Access points

| Service | URL | Purpose |
|---|---|---|
| WordPress site | https://login.42.fr | Main site |
| WP admin | https://login.42.fr/wp-admin | Login as admin user (set in `.env`) |
| Adminer | http://localhost:8082 | DB browser |
| Static site | http://localhost:8081 | Standalone HTML page |
| cAdvisor | http://localhost:8080 | Container resource metrics |
| Uptime Kuma | http://localhost:3001 | Uptime dashboard |
| FTP | port 21 | File access to WP root |

## Common commands

```bash
make start    # start stack
make stop     # stop stack
make down     # stop + remove containers
make clean    # down + prune docker system
make fclean   # clean + wipe data directories
make re       # fclean + all
```

## Data persistence

WordPress files and DB data live on host at `/home/jbahmida/data/`. Survives container restarts and rebuilds. Wiped only by `make fclean`.

## Login credentials

- WP admin: username set in `.env` (`WP_ADMIN_USER`), password in `secrets/credentials.txt`.
- Second WP user: `WP_USER` in `.env`, same credentials file.
- DB root/user passwords: `secrets/db_root_password.txt`, `secrets/db_password.txt`.

Never in `.env`. Never hardcoded.

## Troubleshooting

| Symptom | Check |
|---|---|
| Site won't load | `docker ps` — all containers "Up"? |
| TLS warning in browser | Expected — self-signed cert |
| WP admin login fails | Confirm `credentials.txt` matches what you're typing |
| Container restarting in loop | `docker logs <container>` |
| DB connection errors | Check MariaDB healthy: `docker inspect mariadb` |

## Notes

- Grafana/Prometheus not included in this build.
- Only port 443 is the public entrypoint for the site itself; other ports are for admin/monitoring tools.