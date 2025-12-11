# User Documentation

This guide explains how to use and manage the Inception infrastructure as an end user or administrator.

## Table of Contents
- [Services Overview](#services-overview)
- [Starting and Stopping](#starting-and-stopping)
- [Accessing Services](#accessing-services)
- [Managing Credentials](#managing-credentials)
- [Service Health Checks](#service-health-checks)
- [Troubleshooting](#troubleshooting)

---

## Services Overview

The Inception stack provides the following services:

### Core Services (Mandatory)

| Service | Purpose | Port |
|---------|---------|------|
| **NGINX** | Web server with HTTPS | 443 |
| **WordPress** | Content Management System | - |
| **MariaDB** | Database server | 3306 (internal) |

### Bonus Services

| Service | Purpose | Port |
|---------|---------|------|
| **Redis** | WordPress cache (improves performance) | 6379 (internal) |
| **FTP** | File transfer for WordPress files | 21, 21000-21010 |
| **Adminer** | Database administration web interface | 8080 |
| **cAdvisor** | Container monitoring dashboard | 8081 |

All services run in isolated Docker containers and communicate through a secure private network.

---

## Starting and Stopping

### Prerequisites

Ensure you are in the project directory:
```bash
cd ~/inception
```

### Starting the Infrastructure

To start all services:
```bash
make
```

Or use these individual commands:
```bash
make build    # Build Docker images (first time or after changes)
make up       # Start all containers
```

**Expected output:**
```
✓ Network inception_inception_net       Created
✓ Container mariadb                     Started
✓ Container redis                       Started
✓ Container wordpress                   Started
✓ Container nginx                       Started
✓ Container ftp                         Started
✓ Container adminer                     Started
✓ Container cadvisor                    Started
```

### Stopping the Infrastructure

To stop all services:
```bash
make down
```

This stops containers but preserves your data (WordPress content, database).

### Restarting Services

To restart all services:
```bash
make restart
```

Or restart the entire stack from scratch:
```bash
make re    # Warning: This removes all data!
```

---

## Accessing Services

### From the Virtual Machine

If you're logged directly into the VM:

**WordPress Website:**
```
https://eschwart.42.fr
```
*(Accept the self-signed certificate warning)*

**Database Administration (Adminer):**
```
http://localhost:8080
```

**Container Monitoring (cAdvisor):**
```
http://localhost:8081
```

**FTP Server:**
```bash
ftp localhost 21
# Or using make:
make ftp
```

### From Your Host Machine (k1r3p15 or evaluation computer)

#### Method 1: SSH Tunnel (Recommended)

Open an SSH tunnel with port forwarding:
```bash
ssh -L 8443:localhost:443 -L 8080:localhost:8080 -L 8081:localhost:8081 eschwart@<VM_IP>
```

Then access in your browser:
- **WordPress:** `https://localhost:8443`
- **Adminer:** `http://localhost:8080`
- **cAdvisor:** `http://localhost:8081`

#### Method 2: Update WordPress URL

If you need to access without changing ports, update the WordPress URL:

```bash
# Switch to localhost for host access
make url_host

# Access: https://localhost:8443
```

When done, switch back:
```bash
# Switch back to eschwart.42.fr
make url_vm
```

**Important:** The `url_host`/`url_vm` commands automatically flush the Redis cache to prevent redirect issues.

---

## Managing Credentials

### Credential Storage

All passwords are stored securely in the `secrets/` directory at the root of the project:

```
secrets/
├── mysql_root_password.txt       # MariaDB root password
├── mysql_password.txt            # MariaDB wp_user password
├── wordpress_admin_password.txt  # WordPress admin account
├── wordpress_db_password.txt     # WordPress database connection
├── wordpress_user_password.txt   # WordPress author account
├── redis_password.txt            # Redis cache password
└── ftp_password.txt              # FTP server password
```

### Viewing Credentials

To view a password:
```bash
cat secrets/mysql_root_password.txt
```

**Security Note:** These files are NOT committed to git (excluded by `.gitignore`). Keep them secure and never share them publicly.

### Service Login Information

#### WordPress Admin Panel

**URL:** `https://eschwart.42.fr/wp-admin` (or `https://localhost:8443/wp-admin`)

**Credentials:**
- **Username:** `eschwart` (defined in `srcs/.env`)
- **Password:** Content of `secrets/wordpress_admin_password.txt`

#### WordPress Author Account

**Credentials:**
- **Username:** `wpuser` (defined in `srcs/.env`)
- **Password:** Content of `secrets/wordpress_user_password.txt`

#### Adminer (Database Admin)

**URL:** `http://localhost:8080`

**Credentials:**
- **System:** MySQL
- **Server:** `mariadb`
- **Username:** `wp_user` (defined in `srcs/.env`)
- **Password:** Content of `secrets/mysql_password.txt`
- **Database:** `wordpress`

#### FTP Server

**Connection:**
```bash
ftp localhost 21
# Or: make ftp
```

**Credentials:**
- **Username:** `ftp_user` (defined in `srcs/.env`)
- **Password:** Content of `secrets/ftp_password.txt`

**Files location:** `/home/ftp_user/wordpress/`

#### MariaDB Database

**Connection from WordPress container:**
```bash
docker exec -it mariadb mysql -u root -p
# Enter password from secrets/mysql_root_password.txt
```

### Changing Credentials

1. **Edit the secret file:**
   ```bash
   echo "new_password_here" > secrets/mysql_password.txt
   ```

2. **Recreate the affected service:**
   ```bash
   docker compose -f srcs/docker-compose.yml up -d --force-recreate mariadb
   ```

3. **For WordPress passwords**, also update in WordPress admin or use WP-CLI:
   ```bash
   docker exec wordpress wp user update eschwart --user_pass="new_password" --allow-root
   ```

---

## Service Health Checks

### Quick Status Check

View all running containers:
```bash
make ps
```

**Expected output:**
```
NAME       STATUS         PORTS
nginx      Up 2 minutes   0.0.0.0:443->443/tcp
wordpress  Up 2 minutes   9000/tcp
mariadb    Up 2 minutes   3306/tcp
redis      Up 2 minutes   6379/tcp
ftp        Up 2 minutes   0.0.0.0:21->21/tcp
adminer    Up 2 minutes   0.0.0.0:8080->8080/tcp
cadvisor   Up 2 minutes   0.0.0.0:8081->8081/tcp
```

All containers should show "Up" status.

### Detailed Container Status

```bash
docker ps
```

### View Service Logs

**All services:**
```bash
make logs
```

**Specific service:**
```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

**Follow logs in real-time:**
```bash
docker logs -f nginx
```

### Test Web Services

**Test NGINX:**
```bash
curl -k -I https://localhost:443/
```
Should return HTTP/1.1 301 or 200

**Test WordPress:**
```bash
curl -k https://localhost:443/
```
Should return HTML content

**Test Adminer:**
```bash
curl -I http://localhost:8080/
```
Should return HTTP/1.1 200

**Test cAdvisor:**
```bash
curl -I http://localhost:8081/
```
Should return HTTP/1.1 307 (redirect)

### Check Redis Cache

Verify Redis is working with WordPress:
```bash
docker exec wordpress wp redis status --allow-root
```

**Expected output:**
```
Status: Connected
Client: Predis
...
```

### Check Database Connection

Test MariaDB is accessible:
```bash
docker exec mariadb mysqladmin -u root -p$(cat secrets/mysql_root_password.txt) ping
```

Should return: `mysqld is alive`

### Check FTP Server

Test FTP connection:
```bash
echo "quit" | ftp localhost 21
```

Should connect successfully and show:
```
Connected to localhost.
220 Welcome to FTP Server
```

### Monitor Container Resources

Access cAdvisor dashboard:
```
http://localhost:8081
```

This shows:
- CPU usage per container
- Memory usage
- Network traffic
- Disk I/O

### Data Persistence Check

Verify data directories exist and contain data:
```bash
ls -lh /home/eschwart/data/wordpress/
ls -lh /home/eschwart/data/mariadb/
```

Both directories should contain files (WordPress installation and MariaDB tables).

---

## Troubleshooting

### Container Won't Start

**Check logs:**
```bash
docker logs <container_name>
```

**Common issues:**
- Secret file missing or empty
- Port already in use
- Insufficient permissions on data directories

### Website Shows "Error Establishing Database Connection"

1. **Check MariaDB is running:**
   ```bash
   docker ps | grep mariadb
   ```

2. **Check MariaDB logs:**
   ```bash
   docker logs mariadb
   ```

3. **Verify database credentials:**
   ```bash
   cat secrets/wordpress_db_password.txt
   ```

4. **Restart WordPress:**
   ```bash
   docker restart wordpress
   ```

### SSL Certificate Warning

This is normal. The project uses a self-signed certificate for HTTPS. Click "Advanced" → "Proceed" in your browser.

### FTP Can't Write Files

Check file permissions in WordPress container:
```bash
docker exec wordpress ls -la /var/www/html/
```

Files should be owned by `www-data:www-data`.

### Redis Not Working

1. **Check Redis is running:**
   ```bash
   docker ps | grep redis
   docker logs redis
   ```

2. **Verify WordPress Redis plugin:**
   ```bash
   docker exec wordpress wp plugin list --allow-root
   docker exec wordpress wp redis status --allow-root
   ```

3. **Re-enable Redis:**
   ```bash
   docker exec wordpress wp redis enable --allow-root
   ```

### Cannot Access from Host Machine

1. **Verify SSH tunnel is active:**
   ```bash
   # On host machine (k1r3p15)
   ss -tlnp | grep 8443
   ```

2. **Check WordPress URL:**
   ```bash
   docker exec wordpress wp option get siteurl --allow-root
   ```
   Should match `https://localhost:8443` when using tunnel

3. **Switch URL if needed:**
   ```bash
   make url_host
   ```

### Containers Keep Restarting

1. **Check for port conflicts:**
   ```bash
   ss -tlnp | grep -E '443|8080|8081|21'
   ```

2. **Check Docker logs:**
   ```bash
   docker compose -f srcs/docker-compose.yml logs
   ```

3. **Check system resources:**
   ```bash
   df -h        # Disk space
   free -h      # Memory
   ```

### Data Loss After Restart

If using `make clean` or `make fclean`, data is intentionally removed.

**To preserve data:**
- Use `make down` instead of `make clean`
- Create backups regularly: `make backup`

**To restore from backup:**
```bash
make restore
```

This restores the most recent backup from `~/inception_backup/`.

---

## Backup and Restore

### Creating a Backup

```bash
make backup
```

Creates timestamped backups in `~/inception_backup/`:
- `wordpress_YYYYMMDD_HHMMSS/`
- `mariadb_YYYYMMDD_HHMMSS/`

### Restoring from Backup

```bash
make restore
```

Automatically restores the most recent backup.

### Viewing Available Backups

```bash
ls -lh ~/inception_backup/
```

### Removing Old Backups

```bash
make clean-backup
```

**Warning:** This removes ALL backups!

---

## Support

For issues or questions:
1. Check the logs: `make logs`
2. Verify service status: `make ps`
3. Review this documentation
4. Check the main [README.md](README.md) for technical details
5. Consult Docker documentation: https://docs.docker.com/

---

*Last updated: December 2025*
