# USER_DOC.md - Inception Stack User Documentation

## Overview

This document provides instructions for end-users and administrators on how to manage and use the Inception Docker stack. The stack provides a complete WordPress ecosystem with NGINX, MariaDB, and PHP-FPM for a secure, isolated, and production-ready environment.

---

## Services Provided

The Inception stack includes three core services:

| Service | Purpose | Access |
|---------|---------|--------|
| **NGINX** | Web server with TLS encryption (port 443) | https://emalungo.42.fr |
| **WordPress** | Content management system (php-fpm) | Via NGINX |
| **MariaDB** | MySQL-compatible database | Internal network only |

---

## Getting Started

### Starting the Project

To start all services in the background:

```bash
make up
```

This command will:
- Create necessary volumes at `/home/emalungo/data/`
- Build Docker images (if not already built)
- Start all containers (mariadb, wordpress, nginx)
- Apply restart policies automatically

### Stopping the Project

To stop all running services:

```bash
make down
```

### Restarting Services

To restart all services:

```bash
make restart
```

### Full Rebuild (Clean + Restart)

To perform a complete rebuild with fresh volumes:

```bash
make re
```

⚠️ **Warning**: This will delete all volumes and data. Use only if you need a fresh start.

---

## Accessing the Website

### WordPress Website

- **URL**: https://emalungo.42.fr
- **Protocol**: HTTPS (TLSv1.2 or TLSv1.3)

#### Important Notes:

1. If accessing locally, you may need to add the domain to your `/etc/hosts`:
   ```bash
   echo "127.0.0.1 emalungo.42.fr" >> /etc/hosts
   ```

2. You may receive a self-signed certificate warning (expected for development):
   - Accept the certificate or add it to your browser's trusted certs

---

## Administration Panel

### Accessing WordPress Admin

1. Navigate to: https://emalungo.42.fr/wp-admin
2. Log in with **Administrator Credentials** (see below)

### Administrator Credentials

| User Type | Username | Password |
|-----------|----------|----------|
| Administrator | emanuelmalungo | See credentials file |
| Editor | emalungo | See credentials file |

---

## Credential Management

### Locating Credentials

All sensitive credentials are stored in the `secrets/` folder at the root of the project:

```
secrets/
├── db_password.txt           # WordPress database user password
├── db_root_password.txt      # MariaDB root password
├── wp_admin_password.txt     # WordPress admin password
└── wp_editor_password.txt    # WordPress editor password
```

### Security Notes

- ⚠️ **Never** commit these files to Git
- These files are used via Docker Secrets (not environment variables)
- Credentials are securely injected at runtime into containers
- Each file contains a single password value

### Changing Passwords

To change a password:

1. Edit the corresponding file in `secrets/`
2. Rebuild the containers:
   ```bash
   make re
   ```

---

## Monitoring Services

### Check Service Status

To view the status of all running containers:

```bash
make ps
```

Expected output example:
```
NAME      IMAGE                COMMAND              STATUS
mariadb   mariadb:inception    "/usr/local/bin/..." running
wordpress wordpress:inception  "/usr/local/bin/..." running
nginx     nginx:inception      "/usr/local/bin/..." running
```

### View Logs

To follow real-time logs from all services:

```bash
make logs
```

To view logs from a specific service:

```bash
docker compose -p inception -f srcs/docker-compose.yml logs <service_name>
```

Example: `docker compose -p inception -f srcs/docker-compose.yml logs wordpress`

### Access Container Shell

To execute commands inside a container:

```bash
make shell
```

You'll be prompted to enter the service name (mariadb, wordpress, or nginx).

---

## Health Checks

### Verify NGINX is Active

```bash
curl -k https://emalungo.42.fr
```

You should receive an HTTP response (even if it's a redirect).

### Verify WordPress is Running

```bash
curl -k https://emalungo.42.fr/wp-admin
```

Should return a login page.

### Verify Database Connection

From the wordpress container:

```bash
docker compose -p inception exec wordpress mysql -h mariadb -u emalungo -p wp_db -e "SELECT 1;"
```

(Enter the db_password when prompted)

### Check Docker Network

```bash
docker network inspect inception_network
```

All three services should be connected to this network.

---

## Data Persistence

### Volume Locations

All data persists in the following directories on your host machine:

```
/home/emalungo/data/
├── mariadb/        # Database files
└── wordpress/      # Website files and uploads
```

These volumes are Docker named volumes (not bind mounts), providing better performance and portability.

### Backup Data

To backup your WordPress and database:

```bash
# Backup WordPress files
tar -czf wordpress_backup.tar.gz /home/emalungo/data/wordpress/

# Backup MariaDB
docker compose -p inception exec mariadb mysqldump -u root -p wp_db > db_backup.sql
```

---

## Troubleshooting

### Containers Won't Start

1. Check logs:
   ```bash
   make logs
   ```

2. Verify Docker is installed:
   ```bash
   docker --version
   docker compose version
   ```

3. Ensure no port conflicts (port 443 must be free)

### Cannot Access Website

1. Check if containers are running:
   ```bash
   make ps
   ```

2. Verify domain is in `/etc/hosts`:
   ```bash
   grep emalungo.42.fr /etc/hosts
   ```

3. Check NGINX logs:
   ```bash
   docker compose -p inception logs nginx
   ```

### Database Connection Failed

1. Check MariaDB is running:
   ```bash
   docker compose -p inception logs mariadb
   ```

2. Verify db credentials in `secrets/db_password.txt`

3. Check WordPress logs:
   ```bash
   docker compose -p inception logs wordpress
   ```

### Permission Denied Errors

If you see permission errors on volumes:

```bash
sudo chown -R $USER:$USER /home/emalungo/data/
```

---

## Common Tasks

### Restart WordPress

```bash
docker compose -p inception restart wordpress
```

### Restart Database

```bash
docker compose -p inception restart mariadb
```

### Rebuild a Single Container

```bash
docker compose -p inception -f srcs/docker-compose.yml build --no-cache wordpress
docker compose -p inception restart wordpress
```

### Clean Up Everything

```bash
make fclean  # Removes all containers, volumes, images, and networks
```

---

## Additional Help

For more detailed technical information, see:

- **DEV_DOC.md** - Developer setup and deployment guide
- **README.md** - Project overview and resources
- **Makefile** - Available commands and automation

For support, contact your system administrator or refer to the Docker and WordPress documentation.
