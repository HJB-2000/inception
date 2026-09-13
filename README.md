## This project has been created as part of the 42 curriculum by jbahmida

# Inception Project

This repository contains a Docker-based web platform built as part of the 42 school project, "Inception". The stack runs several services in isolated containers and exposes a production-like architecture for a WordPress site behind NGINX with TLS.

The current build intentionally includes the following services:
- MariaDB
- WordPress + PHP-FPM
- NGINX with TLS
- Redis
- FTP
- Static site
- Adminer
- cAdvisor
- Uptime Kuma

## Project goals
- Build a multi-container environment with Docker Compose.
- Use custom Dockerfiles for each service.
- Handle environment configuration securely with `.env` and Docker secrets.
- Provide persistence for the database and WordPress files.
- Expose a WordPress site through HTTPS and a reverse proxy.

## Architecture overview
The stack is contained in a single Docker network called `inception`. Each service is built from its own Dockerfile under `srcs/requirements/` and runs in a dedicated container.

The main workflow is:
1. MariaDB initializes the database and stores data on a bind-mounted volume.
2. WordPress starts after MariaDB is healthy and connects to the database.
3. NGINX terminates TLS and serves the WordPress site.
4. Redis improves caching and application performance.
5. Auxiliary services provide administration and monitoring support.

## Folder structure
- `srcs/docker-compose.yml` — container orchestration
- `srcs/requirements/` — service-specific Dockerfiles and configuration
- `secrets/` — credentials and secret files
- `Makefile` — convenience commands for build, stop, clean, and restart workflow

## Required environment
A `.env` file should exist in the project root or in the directory expected by the Compose stack. It must include the domain and user variables required by the Docker services.

Typical values include:
- `DOMAIN_NAME`
- `WP_TITLE`
- `WP_ADMIN_USER`
- `WP_ADMIN_PASSWORD`
- `WP_ADMIN_EMAIL`
- `WP_USER`
- `WP_USER_PASSWORD`
- `WP_USER_EMAIL`
- `FTP_USER`
- `MYSQL_DATABASE`
- `MYSQL_USER`
- `MYSQL_PASSWORD`
- `MYSQL_ROOT_PASSWORD`

The repository also stores secret material under `secrets/` for runtime use by Docker secrets.

## Build and run
From the project root, use:
```bash
make all
```
This creates the required host directories, builds the images, and starts the stack.

### Useful commands
```bash
make stop
make start
make down
make clean
make fclean
make re
```

## Service access
After the stack is running, the main endpoints are:
- HTTPS: `https://jbahmida.42.fr`
- Adminer: `http://localhost:8082`
- Uptime Kuma: `http://localhost:3001`
- cAdvisor: `http://localhost:8080`
- Static site: `http://localhost:8081`
- FTP: `ftp://localhost`

## Data persistence
The project stores persistent data in host directories under `/home/jbahmida/data/`:
- `wordpress`
- `mariadb`
- `uptime_kuma`

This ensures the database and WordPress content remain available across container restarts and rebuilds.

## Concepts

**VM vs Docker**
- VM: full OS + hypervisor. Heavy, slow boot.
- Docker: shares host kernel. Light, fast.
- VM: hardware-level. Docker: OS-level.

**Secrets vs Env Vars**
- Env vars: plaintext, visible via `docker inspect`.
- Secrets: encrypted, mounted as files, tmpfs.
- Secrets -> passwords/keys. Env vars -> config.

**Docker Network vs Host Network**
- Bridge: isolated subnet, own IP, needs port mapping.
- Host: shares host stack, no isolation, no mapping.
- Bridge = default/secure. Host = perf.

**Volumes vs Bind Mounts**
- Volumes: Docker-managed, `/var/lib/docker/volumes/`. Portable.
- Bind mounts: direct host path. Host-dependent.
- Volumes = prod. Bind mounts = dev.

## Notes
- The stack is intended to be run on a Linux host with Docker and Docker Compose available.
- The current configuration matches the active build.
- Any future changes should keep documentation aligned with the actual service set in `srcs/docker-compose.yml`.

## Summary
This project demonstrates a working multi-service container architecture with secure configuration, persistent storage, and a clean deployment workflow. It is designed to provide a complete site environment for WordPress with supporting tooling for monitoring, file transfer, and maintenance.