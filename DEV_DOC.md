# Developer Documentation

This guide explains how to set up, build, and manage the Inception infrastructure from a developer's perspective.

## Table of Contents
- [Environment Setup](#environment-setup)
- [Building and Launching](#building-and-launching)
- [Container Management](#container-management)
- [Volume and Data Management](#volume-and-data-management)
- [Development Workflow](#development-workflow)
- [Architecture Overview](#architecture-overview)

---

## Environment Setup

### Prerequisites

Ensure the following are installed on your system:

```bash
# Check Docker
docker --version        # Should be 20.10+
docker compose version  # Should be 2.0+

# Check Make
make --version

# Check other tools
openssl version        # For SSL certificate generation
git --version         # For version control
```

**System Requirements:**
- Debian-based Linux (Debian 12 recommended)
- Minimum 2GB RAM
- Minimum 10GB free disk space
- Root/sudo access for data directory creation

### Initial Setup

1. **Clone the repository:**
   ```bash
   git clone <repository_url>
   cd inception
   ```

2. **Create data directories:**
   ```bash
   sudo mkdir -p /home/<login>/data/mariadb
   sudo mkdir -p /home/<login>/data/wordpress
   sudo chown -R <login>:<login> /home/<login>/data
   ```

3. **Create secrets directory:**
   ```bash
   mkdir -p secrets
   ```

4. **Generate secure passwords:**
   ```bash
   # Generate random passwords (recommended)
   openssl rand -base64 32 > secrets/mysql_root_password.txt
   openssl rand -base64 32 > secrets/mysql_password.txt
   openssl rand -base64 32 > secrets/wordpress_admin_password.txt
   openssl rand -base64 32 > secrets/wordpress_db_password.txt
   openssl rand -base64 32 > secrets/wordpress_user_password.txt
   openssl rand -base64 32 > secrets/redis_password.txt
   openssl rand -base64 32 > secrets/ftp_password.txt
   
   # Or use simple passwords for development
   echo "root_password" > secrets/mysql_root_password.txt
   echo "db_password" > secrets/mysql_password.txt
   echo "admin_password" > secrets/wordpress_admin_password.txt
   echo "db_password" > secrets/wordpress_db_password.txt
   echo "user_password" > secrets/wordpress_user_password.txt
   echo "redis_password" > secrets/redis_password.txt
   echo "ftp_password" > secrets/ftp_password.txt
   ```

5. **Configure environment variables:**
   
   Edit `srcs/.env` and customize the following:

   ```bash
   # MariaDB
   MYSQL_DATABASE=wordpress
   MYSQL_USER=wp_user
   
   # WordPress Database Connection
   WORDPRESS_DB_HOST=mariadb
   WORDPRESS_DB_NAME=wordpress
   WORDPRESS_DB_USER=wp_user
   
   # WordPress Admin Account
   WORDPRESS_ADMIN_USER=<your_login>
   WORDPRESS_ADMIN_EMAIL=<your_login>@inception.com
   
   # WordPress Test Account
   WORDPRESS_USER=wpuser
   WORDPRESS_USER_EMAIL=wpuser@inception.com
   
   # WordPress Site Configuration
   WORDPRESS_URL=https://<your_login>.42.fr
   WORDPRESS_TITLE=My Inception Site
   
   # Redis
   REDIS_HOST='redis'
   REDIS_PORT=6379
   
   # FTP
   FTP_USER=ftp_user
   ```

### Configuration Files Overview

```
inception/
├── srcs/
│   ├── .env                          # Environment variables
│   ├── docker-compose.yml            # Container orchestration
│   └── requirements/
│       ├── mariadb/
│       │   ├── Dockerfile            # MariaDB image definition
│       │   └── tools/entrypoint.sh   # Database initialization script
│       ├── wordpress/
│       │   ├── Dockerfile            # WordPress + PHP-FPM image
│       │   └── tools/entrypoint.sh   # WordPress setup script
│       ├── nginx/
│       │   ├── Dockerfile            # NGINX image
│       │   └── conf/nginx.conf       # NGINX configuration
│       ├── redis/
│       │   ├── Dockerfile            # Redis cache image
│       │   └── tools/entrypoint.sh   # Redis initialization
│       ├── ftp/
│       │   ├── Dockerfile            # vsftpd image
│       │   └── tools/entrypoint.sh   # FTP server setup
│       ├── adminer/
│       │   └── Dockerfile            # Adminer database admin
│       └── cadvisor/
│           └── Dockerfile            # cAdvisor monitoring
├── secrets/                          # Password files (not in git)
└── Makefile                          # Build automation
```

---

## Building and Launching

### Basic Build and Launch

```bash
# Build all images and start containers
make

# Or step by step:
make build    # Build Docker images from Dockerfiles
make up       # Start all containers in detached mode
```

### Makefile Commands Reference

| Command | Description |
|---------|-------------|
| `make` or `make all` | Build images and start containers |
| `make build` | Build all Docker images |
| `make up` | Start all containers (detached mode) |
| `make down` | Stop all containers (preserves data) |
| `make restart` | Restart all containers |
| `make logs` | View logs from all containers (follow mode) |
| `make ps` | List running containers |
| `make clean` | Stop containers and remove data directories |
| `make fclean` | Full cleanup (containers, images, volumes, networks) |
| `make re` | Rebuild everything from scratch |

### Advanced Makefile Commands

| Command | Description |
|---------|-------------|
| `make backup` | Create timestamped backup of WordPress and MariaDB data |
| `make restore` | Restore latest backup |
| `make clean-backup` | Remove all backup files |
| `make url_host` | Switch WordPress URL to `localhost:8443` (for SSH tunnel access) |
| `make url_vm` | Switch WordPress URL to `<login>.42.fr` (for VM access) |
| `make ftp` | Connect to FTP server |

### Docker Compose Commands

```bash
# Navigate to docker-compose directory
cd srcs/

# Build specific service
docker compose build nginx
docker compose build wordpress

# Start specific service
docker compose up -d nginx

# Stop specific service
docker compose stop wordpress

# Restart specific service
docker compose restart mariadb

# View logs for specific service
docker compose logs -f nginx

# Rebuild and restart service
docker compose up -d --build nginx

# Force recreate container (useful after secret changes)
docker compose up -d --force-recreate mariadb
```

### Build Process Explained

When you run `make build`:

1. **Docker reads each Dockerfile** in `srcs/requirements/*/`
2. **Base images are pulled** (debian:bookworm, alpine:3.19)
3. **Packages are installed** (mariadb, php-fpm, nginx, redis, etc.)
4. **Configuration files are copied** into images
5. **Entrypoint scripts are made executable**
6. **Images are tagged** as `inception-<service>`

When you run `make up`:

1. **Docker Compose creates network** `inception_net`
2. **Secrets are mounted** from `../secrets/` to `/run/secrets/` in containers
3. **Volumes are created/mounted**:
   - Bind mounts: `/home/<login>/data/mariadb`, `/home/<login>/data/wordpress`
   - Named volume: `wordpress_data` (shared between WordPress and FTP)
4. **Containers start in dependency order**:
   - MariaDB first (no dependencies)
   - Redis (no dependencies)
   - WordPress (depends on MariaDB and Redis)
   - NGINX (depends on WordPress)
   - FTP (depends on WordPress for volume)
   - Adminer (no dependencies)
   - cAdvisor (no dependencies)

---

## Container Management

### Viewing Container Status

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# View resource usage
docker stats

# View detailed container info
docker inspect <container_name>
```

### Accessing Containers

```bash
# Execute command in running container
docker exec <container_name> <command>

# Open interactive shell
docker exec -it nginx sh           # Alpine uses sh
docker exec -it wordpress bash     # Debian uses bash
docker exec -it mariadb bash

# Run command as specific user
docker exec -u www-data wordpress ls -la /var/www/html/
```

### Common Container Operations

**MariaDB:**
```bash
# Access MySQL CLI as root
docker exec -it mariadb mysql -u root -p$(cat secrets/mysql_root_password.txt)

# Check database status
docker exec mariadb mysqladmin -u root -p$(cat secrets/mysql_root_password.txt) ping

# List databases
docker exec mariadb mysql -u root -p$(cat secrets/mysql_root_password.txt) -e "SHOW DATABASES;"

# Dump database
docker exec mariadb mysqldump -u root -p$(cat secrets/mysql_root_password.txt) wordpress > backup.sql

# Restore database
cat backup.sql | docker exec -i mariadb mysql -u root -p$(cat secrets/mysql_root_password.txt) wordpress
```

**WordPress:**
```bash
# Check WordPress status
docker exec wordpress wp core version --allow-root

# List plugins
docker exec wordpress wp plugin list --allow-root

# List users
docker exec wordpress wp user list --allow-root

# Check Redis cache status
docker exec wordpress wp redis status --allow-root

# Flush Redis cache
docker exec wordpress wp redis flush --allow-root

# Update WordPress URL
docker exec wordpress wp option update siteurl 'https://localhost:8443' --allow-root
docker exec wordpress wp option update home 'https://localhost:8443' --allow-root
```

**Redis:**
```bash
# Connect to Redis CLI
docker exec -it redis redis-cli

# Authenticate (inside redis-cli)
AUTH <password_from_secrets/redis_password.txt>

# Check Redis info
INFO

# Monitor Redis commands
MONITOR

# Check cache keys
KEYS *
```

**NGINX:**
```bash
# Test NGINX configuration
docker exec nginx nginx -t

# Reload NGINX configuration
docker exec nginx nginx -s reload

# View NGINX access logs
docker exec nginx tail -f /var/log/nginx/access.log

# View NGINX error logs
docker exec nginx tail -f /var/log/nginx/error.log
```

### Container Logs

```bash
# View all logs
docker compose -f srcs/docker-compose.yml logs

# Follow logs in real-time
docker compose -f srcs/docker-compose.yml logs -f

# View logs for specific service
docker logs nginx
docker logs -f wordpress    # Follow mode

# View last 50 lines
docker logs --tail 50 mariadb

# View logs with timestamps
docker logs -t wordpress
```

### Stopping and Removing Containers

```bash
# Stop all containers
docker compose -f srcs/docker-compose.yml down

# Stop specific container
docker stop nginx

# Stop and remove specific container
docker rm -f wordpress

# Remove all stopped containers
docker container prune

# Remove all containers (dangerous!)
docker rm -f $(docker ps -aq)
```

---

## Volume and Data Management

### Volume Architecture

The project uses two types of volumes:

**1. Bind Mounts (Host → Container)**
```yaml
volumes:
  - /home/<user>/data/mariadb:/var/lib/mysql
  - /home/<user>/data/wordpress:/var/www/html
```

**Purpose:** Persistent data that survives container deletion

**2. Named Volumes (Docker-managed)**
```yaml
volumes:
  wordpress_data:

services:
  wordpress:
    volumes:
      - wordpress_data:/var/www/html
  ftp:
    volumes:
      - wordpress_data:/home/ftp_user/wordpress
```

**Purpose:** Share data between WordPress and FTP containers

### Inspecting Volumes

```bash
# List all volumes
docker volume ls

# Inspect specific volume
docker volume inspect inception_wordpress_data

# View volume mount points in container
docker inspect wordpress | grep -A 10 Mounts
```

### Data Directory Structure

**MariaDB Data:**
```bash
/home/<user>/data/mariadb/
├── aria_log_control
├── ib_buffer_pool
├── ibdata1
├── ib_logfile0
├── mysql/              # System database
├── performance_schema/ # Performance data
└── wordpress/          # WordPress database
    ├── wp_commentmeta.ibd
    ├── wp_comments.ibd
    ├── wp_options.ibd
    ├── wp_posts.ibd
    ├── wp_users.ibd
    └── ...
```

**WordPress Data:**
```bash
/home/<user>/data/wordpress/
├── index.php
├── wp-admin/
├── wp-content/
│   ├── plugins/
│   │   └── redis-cache/
│   ├── themes/
│   │   └── twentytwentyfour/
│   └── uploads/
├── wp-includes/
├── wp-config.php
└── ...
```

### Accessing Data on Host

```bash
# View MariaDB data
sudo ls -lah /home/<login>/data/mariadb/

# View WordPress files
ls -lah /home/<login>/data/wordpress/

# Edit WordPress config (if needed)
nano /home/<login>/data/wordpress/wp-config.php

# Check disk usage
du -sh /home/<login>/data/mariadb/
du -sh /home/<login>/data/wordpress/
```

### Backup and Restore Data

**Using Makefile:**
```bash
# Create backup (copies to ~/inception_backup/)
make backup

# Restore latest backup
make restore

# View backups
ls -lh ~/inception_backup/
```

**Manual Backup:**
```bash
# Backup MariaDB
sudo cp -r /home/<login>/data/mariadb ~/mariadb_backup_$(date +%Y%m%d)

# Backup WordPress
sudo cp -r /home/<login>/data/wordpress ~/wordpress_backup_$(date +%Y%m%d)

# Database dump
docker exec mariadb mysqldump -u root -p$(cat secrets/mysql_root_password.txt) \
  --all-databases > db_backup_$(date +%Y%m%d).sql
```

**Manual Restore:**
```bash
# Stop containers first
make down

# Restore MariaDB data
sudo rm -rf /home/<login>/data/mariadb/*
sudo cp -r ~/mariadb_backup_YYYYMMDD/* /home/<login>/data/mariadb/

# Restore WordPress data
sudo rm -rf /home/<login>/data/wordpress/*
sudo cp -r ~/wordpress_backup_YYYYMMDD/* /home/<login>/data/wordpress/

# Start containers
make up
```

### Cleaning Data

```bash
# Remove all data (use with caution!)
make clean

# Or manually:
sudo rm -rf /home/<login>/data/mariadb/*
sudo rm -rf /home/<login>/data/wordpress/*

# Remove Docker volumes
docker volume rm inception_wordpress_data

# Remove all unused volumes
docker volume prune
```

### Data Persistence Verification

```bash
# Create test post in WordPress
docker exec wordpress wp post create \
  --post_title='Test Post' \
  --post_content='Testing persistence' \
  --post_status='publish' \
  --allow-root

# Stop containers
make down

# Start containers again
make up

# Verify post still exists
docker exec wordpress wp post list --allow-root
```

---

## Development Workflow

### Typical Development Cycle

1. **Make changes to Dockerfile or scripts:**
   ```bash
   nano srcs/requirements/nginx/conf/nginx.conf
   ```

2. **Rebuild affected service:**
   ```bash
   docker compose -f srcs/docker-compose.yml build nginx
   ```

3. **Restart service:**
   ```bash
   docker compose -f srcs/docker-compose.yml up -d nginx
   ```

4. **Check logs:**
   ```bash
   docker logs -f nginx
   ```

5. **Test changes:**
   ```bash
   curl -k -I https://localhost:443/
   ```

### Debugging Tips

**Check if container is running:**
```bash
docker ps | grep nginx
```

**View full container logs:**
```bash
docker logs nginx 2>&1 | less
```

**Inspect container network:**
```bash
docker exec nginx ip addr
docker exec nginx ping mariadb
docker exec nginx nslookup wordpress
```

**Check file permissions:**
```bash
docker exec wordpress ls -la /var/www/html/
docker exec nginx ls -la /etc/nginx/
```

**Test connectivity between containers:**
```bash
# From WordPress to MariaDB
docker exec wordpress nc -zv mariadb 3306

# From WordPress to Redis
docker exec wordpress nc -zv redis 6379

# From NGINX to WordPress
docker exec nginx nc -zv wordpress 9000
```

**Verify secrets are mounted:**
```bash
docker exec mariadb ls -la /run/secrets/
docker exec wordpress cat /run/secrets/wordpress_db_password
```

### Common Development Issues

**Issue: Container exits immediately**
```bash
# Check exit code
docker ps -a

# View logs
docker logs <container_name>

# Common causes:
# - Syntax error in entrypoint script
# - Missing required environment variable
# - Secret file missing
```

**Issue: Cannot connect to database**
```bash
# Verify MariaDB is running
docker ps | grep mariadb

# Check MariaDB logs
docker logs mariadb

# Test connection from WordPress
docker exec wordpress mysql -h mariadb -u wp_user -p$(cat secrets/wordpress_db_password.txt) -e "SHOW DATABASES;"
```

**Issue: NGINX 502 Bad Gateway**
```bash
# Check if WordPress PHP-FPM is running
docker exec wordpress ps aux | grep php-fpm

# Check NGINX can reach WordPress
docker exec nginx nc -zv wordpress 9000

# View NGINX error logs
docker logs nginx
```

---

## Architecture Overview

### Network Architecture

```
inception_net (bridge network)
├── mariadb:3306       (internal only)
├── redis:6379         (internal only)
├── wordpress:9000     (internal only)
├── nginx:443          (exposed to host)
├── ftp:21,21000-21010 (exposed to host)
├── adminer:8080       (exposed to host)
└── cadvisor:8081      (exposed to host)
```

**DNS Resolution:**
- Containers can reach each other by name (e.g., `mariadb`, `wordpress`)
- Docker provides built-in DNS for the bridge network

### Data Flow

**HTTP Request Flow:**
```
User Browser
    ↓ HTTPS (443)
NGINX (SSL termination)
    ↓ HTTP (9000)
WordPress (PHP-FPM)
    ↓ MySQL (3306)
MariaDB
```

**Cache Flow:**
```
WordPress ←→ Redis (6379)
```

**File Access Flow:**
```
FTP Client (21) → FTP Server → wordpress_data volume ← WordPress
```

### Service Dependencies

```
MariaDB (no dependencies)
    ↓
WordPress (depends_on: mariadb, redis)
    ↓
NGINX (depends_on: wordpress)

FTP (depends_on: wordpress for volume)
Redis (no dependencies)
Adminer (no dependencies)
cAdvisor (no dependencies)
```

### Secret Management Flow

```
Host: secrets/*.txt
    ↓ (mounted read-only)
Container: /run/secrets/*
    ↓ (read by entrypoint)
Entrypoint: VARIABLE=$(cat /run/secrets/password)
    ↓ (used in configuration)
Application: Uses password from variable
```

---

## Quick Reference

### Essential Commands Cheat Sheet

```bash
# Start everything
make

# Stop everything
make down

# View logs
make logs

# Rebuild specific service
docker compose -f srcs/docker-compose.yml build nginx

# Access container
docker exec -it wordpress bash

# View WordPress URL
docker exec wordpress wp option get siteurl --allow-root

# Check Redis cache
docker exec wordpress wp redis status --allow-root

# Database backup
docker exec mariadb mysqldump -u root -p$(cat secrets/mysql_root_password.txt) wordpress > backup.sql

# Test NGINX
curl -k -I https://localhost:443/

# View container IPs
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nginx
```

### File Locations Quick Reference

| Item | Location |
|------|----------|
| Docker Compose | `srcs/docker-compose.yml` |
| Environment Variables | `srcs/.env` |
| Secrets | `secrets/*.txt` |
| MariaDB Data | `/home/<user>/data/mariadb/` |
| WordPress Data | `/home/<user>/data/wordpress/` |
| NGINX Config | `srcs/requirements/nginx/conf/nginx.conf` |
| WordPress Entrypoint | `srcs/requirements/wordpress/tools/entrypoint.sh` |
| MariaDB Entrypoint | `srcs/requirements/mariadb/tools/entrypoint.sh` |
| Backups | `~/inception_backup/` |

---

*Last updated: December 2025*
