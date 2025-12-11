# Inception

*This project has been created as part of the 42 curriculum by eschwart.*

## Description

Inception is a system administration and DevOps project that focuses on Docker containerization. The goal is to set up a small infrastructure composed of multiple services using Docker Compose, with each service running in its own dedicated container built from scratch (no pre-built images from Docker Hub except Alpine/Debian base images).

The project implements a complete web infrastructure with:
- **NGINX** with TLSv1.2/1.3 as a reverse proxy
- **WordPress** with PHP-FPM for content management
- **MariaDB** as the database server
- **Redis** as a caching layer (Bonus)
- **FTP server** (vsftpd) for file management (Bonus)
- **Adminer** for database administration (Bonus)
- **cAdvisor** for container monitoring (Bonus)

All services communicate through a Docker network and use Docker secrets for secure password management.

## Instructions

### Prerequisites

- Docker Engine (version 20.10+)
- Docker Compose (version 2.0+)
- GNU Make
- Debian-based Linux system

### Configuration

1. **Create the secrets directory** and populate it with password files:
```bash
mkdir -p secrets
echo "your_mysql_root_password" > secrets/mysql_root_password.txt
echo "your_mysql_password" > secrets/mysql_password.txt
echo "your_wordpress_admin_password" > secrets/wordpress_admin_password.txt
echo "your_wordpress_db_password" > secrets/wordpress_db_password.txt
echo "your_wordpress_user_password" > secrets/wordpress_user_password.txt
echo "your_redis_password" > secrets/redis_password.txt
echo "your_ftp_password" > secrets/ftp_password.txt
```

2. **Configure environment variables** in `srcs/.env`:
   - Update `WORDPRESS_URL` to match your domain
   - Adjust user names and emails as needed

3. **Set up data directories**:
```bash
sudo mkdir -p /home/<login>/data/mariadb
sudo mkdir -p /home/<login>/data/wordpress
```

### Building and Running

```bash
# Build all images and start services
make

# Or step by step:
make build    # Build Docker images
make up       # Start all containers

# Other useful commands:
make down     # Stop all containers
make restart  # Restart all services
make logs     # View container logs
make ps       # List running containers
```

### Accessing Services

**From the VM:**
- WordPress: `https://<login>.42.fr`
- Adminer: `http://localhost:8080`
- cAdvisor: `http://localhost:8081`
- FTP: `ftp://localhost:21` (user: ftp_user)

**From host machine (using SSH tunnel):**
```bash
ssh -L 8443:localhost:443 -L 8080:localhost:8080 -L 8081:localhost:8081 <login>@<VM_IP>
```
Then access:
- WordPress: `https://localhost:8443`
- Adminer: `http://localhost:8080`
- cAdvisor: `http://localhost:8081`

**Switching URLs for evaluation:**
```bash
make url_host  # Switch to localhost:8443 for host access
make url_vm    # Switch back to <login>.42.fr
```

### Backup and Restore

```bash
make backup         # Create timestamped backup
make restore        # Restore latest backup
make clean-backup   # Remove all backups
```

### Cleaning

```bash
make clean   # Stop containers and remove data
make fclean  # Full cleanup (containers, images, volumes)
make re      # Rebuild everything from scratch
```

## Resources

### Documentation
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress CLI](https://wp-cli.org/)
- [MariaDB Documentation](https://mariadb.com/kb/en/)
- [Redis Documentation](https://redis.io/documentation)
- [vsftpd Documentation](https://security.appspot.com/vsftpd.html)

### Tutorials
- [Docker Networking Deep Dive](https://docs.docker.com/network/)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.php)
- [Self-Signed SSL Certificates](https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx)

### AI Usage

AI (GitHub Copilot with Claude Sonnet 4.5) was used throughout this project for:

**Learning and Research:**
- Understanding Docker secrets vs environment variables
- Comparing Docker networks vs host networking
- Evaluating monitoring tools (Glances vs cAdvisor)
- Best practices for PHP-FPM and NGINX integration
  
**Debugging and Troubleshooting:**
- FTP permissions issues (www-data vs ftp_user ownership)
- Redis integration with WordPress (wp-config.php configuration)
- Docker secrets validation in entrypoint scripts
- SSL certificate generation and NGINX TLS configuration
- Port forwarding conflicts between VS Code and SSH tunnels

**Documentation:**
- Makefile with rules (backup, restore, URL switching)
- README.md structure
- Comment explanations in configuration files

The AI provided explanations and helped validate configurations against the project requirements. 
All AI-generated code was reviewed, tested, and adapted to fit the specific needs of this infrastructure.

## Project Description

### Docker in This Project

This project uses **Docker** to create an isolated, reproducible infrastructure. Each service runs in its own container, built from official Debian 12 (Bookworm) base images using custom Dockerfiles.

**Key Docker concepts used:**
- **Multi-container orchestration** with Docker Compose
- **Custom images** built from Dockerfiles (no pre-built application images)
- **Docker secrets** for secure credential management
- **Bridge networks** for inter-container communication
- **Bind mounts** for persistent data storage
- **Health checks** to ensure service readiness

### Sources and Design Choices

**Service Architecture:**

1. **NGINX** (Alpine 3.19)
   - Reverse proxy with SSL/TLS termination
   - Self-signed certificate generated at build time
   - TLSv1.2 and TLSv1.3 only (modern security)
   - Proxies requests to WordPress PHP-FPM on port 9000

2. **WordPress** (Debian 12 + PHP 8.2-FPM)
   - Installed via WP-CLI (no archive extraction)
   - Configured with Redis object cache plugin
   - Entrypoint script handles initialization and user creation
   - Waits for MariaDB readiness before starting

3. **MariaDB** (Debian 12 + MariaDB 10.11)
   - Custom database initialization script
   - Creates WordPress database and users
   - Uses Docker secrets for root and user passwords
   - Data persisted via bind mount

4. **Redis** (Debian 12 + Redis 7.0)
   - In-memory cache for WordPress
   - Password authentication enabled
   - Improves WordPress performance significantly

5. **FTP Server** (Debian 12 + vsftpd 3.0.3)
   - Provides file access to WordPress directory
   - Passive mode configured (ports 21000-21010)
   - Mounts wordpress_data volume

6. **Adminer** (Debian 12 + PHP 8.2)
   - Lightweight database management interface
   - Single PHP file served by PHP built-in server
   - Accessible on port 8080

7. **cAdvisor** (Official Google image)
   - Container resource monitoring
   - Real-time metrics for all containers
   - Accessible on port 8081

### Comparisons

#### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker |
|--------|------------------|--------|
| **Isolation** | Full OS isolation (hypervisor) | Process-level isolation (kernel namespaces) |
| **Resource Usage** | Heavy (each VM runs full OS) | Lightweight (shares host kernel) |
| **Startup Time** | Minutes | Seconds |
| **Portability** | Large image files (GBs) | Small images (MBs) |
| **Use Case** | Complete OS isolation needed | Microservices, development, CI/CD |

**Choice for Inception:** Docker is ideal because:
- Fast iteration during development
- Lightweight resource usage (7 containers on single VM)
- Easy orchestration with Docker Compose
- Portable across different hosts

#### Secrets vs Environment Variables

| Aspect | Docker Secrets | Environment Variables |
|--------|----------------|----------------------|
| **Security** | Stored in memory, encrypted at rest | Visible in `docker inspect`, process list |
| **Scope** | Mounted as files in `/run/secrets/` | Exposed as shell variables |
| **Rotation** | Can be updated without rebuild | Requires container restart |
| **Visibility** | Not shown in logs or process list | Can leak in error messages |

**Choice for Inception:** Docker secrets because:
- Passwords never appear in code or environment
- Complies with security best practices
- Each service reads secrets from `/run/secrets/` files
- No risk of accidental password exposure in `docker inspect`

Example implementation:
```yaml
services:
  mariadb:
    secrets:
      - mysql_root_password
      - mysql_password

secrets:
  mysql_root_password:
    file: ../secrets/mysql_root_password.txt
```

#### Docker Network vs Host Network

| Aspect | Docker Bridge Network | Host Network |
|--------|----------------------|--------------|
| **Isolation** | Each container gets own IP | Container uses host IP directly |
| **Port Conflicts** | No conflicts (internal ports) | Must manage port conflicts |
| **Performance** | Slight overhead (NAT) | No overhead |
| **Security** | Isolated by default | Direct host network access |

**Choice for Inception:** Docker bridge network (`inception_net`) because:
- Services communicate via container names (DNS resolution)
- Internal ports (e.g., 9000, 3306) not exposed to host
- Better security isolation
- Subject explicitly forbids `network: host`

Example:
```yaml
networks:
  inception_net:
    driver: bridge

services:
  nginx:
    networks:
      - inception_net
```

NGINX connects to WordPress via `wordpress:9000` (container name as hostname).

#### Docker Volumes vs Bind Mounts

| Aspect | Docker Volumes | Bind Mounts |
|--------|----------------|-------------|
| **Management** | Managed by Docker | Manual path management |
| **Location** | `/var/lib/docker/volumes/` | User-specified path |
| **Portability** | Volume name portable | Absolute path required |
| **Backup** | `docker volume` commands | Standard filesystem tools |
| **Permissions** | Docker manages ownership | Host filesystem permissions |

**Choice for Inception:** Mixed approach:

**Bind Mounts** for persistent data (subject requirement):
```yaml
volumes:
  - /home/eschwart/data/mariadb:/var/lib/mysql
  - /home/eschwart/data/wordpress:/var/www/html
```
- Data survives container deletion
- Easy to backup with standard tools (`make backup` uses `sudo cp`)
- Direct access from host for debugging

**Named Volumes** for shared data between containers:
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
- FTP and WordPress share same files
- Docker manages permissions automatically

This hybrid approach provides both persistence (bind mounts) and inter-container sharing (named volumes).

---

## Project Structure

```
inception/
├── Makefile                 # Build and management commands
├── README.md               # This file
├── secrets/                # Password files (not in git)
│   ├── mysql_root_password.txt
│   ├── mysql_password.txt
│   ├── wordpress_admin_password.txt
│   ├── wordpress_db_password.txt
│   ├── wordpress_user_password.txt
│   ├── redis_password.txt
│   └── ftp_password.txt
└── srcs/
    ├── .env                # Environment variables
    ├── docker-compose.yml  # Container orchestration
    └── requirements/
        ├── mariadb/        # Database service
        │   ├── Dockerfile
        │   └── tools/entrypoint.sh
        ├── wordpress/      # CMS service
        │   ├── Dockerfile
        │   └── tools/entrypoint.sh
        ├── nginx/          # Web server
        │   ├── Dockerfile
        │   └── conf/nginx.conf
        ├── redis/          # Cache service
        │   ├── Dockerfile
        │   └── tools/entrypoint.sh
        ├── ftp/            # File server
        │   ├── Dockerfile
        │   └── tools/entrypoint.sh
        ├── adminer/        # DB admin interface
        │   └── Dockerfile
        └── cadvisor/       # Container monitoring
            └── Dockerfile
```

## License

This project is part of the 42 School curriculum.
