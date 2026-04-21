# DEV_DOC.md - Inception Stack Developer Documentation

## Overview

This document provides comprehensive instructions for developers on how to set up, build, deploy, and manage the Inception Docker stack from scratch. It covers prerequisites, configuration, container management, and data persistence.

---

## Prerequisites

Before setting up the Inception project, ensure you have the following installed on your system:

### Required Software

- **Docker** (version 20.10+)
  ```bash
  docker --version
  ```

- **Docker Compose** (version 2.0+)
  ```bash
  docker compose version
  ```

- **GNU Make** (for running Makefile commands)
  ```bash
  make --version
  ```

- **Linux-based OS** (Ubuntu, Debian, Alpine, or similar)
  - The project is designed for VMs/containers, not native Windows/macOS
  - WSL2 (Windows Subsystem for Linux 2) is supported

- **Basic utilities**: curl, openssl, bash, etc.

### System Requirements

- **Minimum RAM**: 2GB (recommended 4GB+)
- **Disk Space**: 5GB free space for images and volumes
- **Network**: Port 443 available (not in use by other services)

---

## Environment Setup from Scratch

### Step 1: Clone/Initialize the Project

```bash
# Navigate to your projects directory
cd ~/Pictures/
git clone <your-repo-url> Inception
cd Inception
```

### Step 2: Create the Secrets Directory

```bash
mkdir -p secrets
```

### Step 3: Configure Secrets

Create the required secret files with passwords:

```bash
# Generate secure passwords (or use your own)
echo "your_db_password" > secrets/db_password.txt
echo "your_db_root_password" > secrets/db_root_password.txt
echo "your_wp_admin_password" > secrets/wp_admin_password.txt
echo "your_wp_editor_password" > secrets/wp_editor_password.txt
```

⚠️ **Security Guidelines**:
- Use strong, unique passwords (minimum 16 characters recommended)
- Never commit these files to Git
- Ensure file permissions are restrictive:
  ```bash
  chmod 600 secrets/*.txt
  ```

### Step 4: Configure Environment Variables

Edit `srcs/.env` with your settings:

```bash
# Domain (must match your username)
DOMAIN_NAME=emalungo.42.fr

# MySQL Setup
MYSQL_USER=emalungo
MYSQL_DATABASE=wp_db
DB_HOST=mariadb

# WordPress Setup
WP_TITLE=Inception
WP_ADMIN_USER=emanuelmalungo      # Cannot contain "admin" or "Admin"
WP_ADMIN_EMAIL=emanuelmalungo@intra.42.fr
WP_EDITOR_USER=emalungo
WP_EDITOR_EMAIL=emalungo@intra.42.fr
```

### Step 5: Configure System-Level Domain Mapping

Add the domain to your `/etc/hosts` file:

```bash
sudo nano /etc/hosts
# Add the following line:
# 127.0.0.1 emalungo.42.fr
```

Or use this command:

```bash
echo "127.0.0.1 emalungo.42.fr" | sudo tee -a /etc/hosts
```

### Step 6: Create Volume Directories

Create the directories where Docker volumes will persist:

```bash
mkdir -p /home/emalungo/data/mariadb
mkdir -p /home/emalungo/data/wordpress
```

The Makefile will also handle this automatically with `make up`.

---

## Building the Project

### Build Images Only (Without Starting)

```bash
make build
```

This command:
- Builds Docker images from Dockerfiles
- Does not start containers
- Useful for testing builds before deployment

### Build Specific Service

```bash
docker compose -p inception -f srcs/docker-compose.yml build --no-cache <service_name>
```

Example: `docker compose -p inception -f srcs/docker-compose.yml build --no-cache nginx`

### Build with Fresh Cache

```bash
docker compose -p inception -f srcs/docker-compose.yml build --no-cache
```

---

## Launching the Project

### Start All Services

```bash
make up
```

This command:
1. Verifies Docker is installed and running
2. Creates volume directories (`/home/emalungo/data/`)
3. Builds images (if not already built)
4. Starts all containers in background
5. Applies restart policies

### Expected Startup Output

```
✅ Creating volume directories...
✅ Volumes created successfully
✅ Starting inception...
[+] Building 2.5s (18/18) FINISHED
...
✅ Nginx pronto!
✅ MariaDB pronto!
✅ WordPress pronto!
```

### Verify Services Started

```bash
make ps
```

Expected output:
```
NAME      IMAGE                COMMAND              STATUS
mariadb   mariadb:inception    "/usr/local/bin/..." running
wordpress wordpress:inception  "/usr/local/bin/..." running
nginx     nginx:inception      "/usr/local/bin/..." running
```

---

## Container Management

### View Container Status

```bash
make ps
```

### View Real-Time Logs

```bash
make logs
```

Press `Ctrl+C` to exit log following.

### View Logs from Specific Service

```bash
docker compose -p inception -f srcs/docker-compose.yml logs <service_name>
docker compose -p inception -f srcs/docker-compose.yml logs -f <service_name>  # Follow mode
```

Examples:
```bash
docker compose -p inception -f srcs/docker-compose.yml logs nginx
docker compose -p inception -f srcs/docker-compose.yml logs -f wordpress
```

### Execute Commands in Container

```bash
make shell
```

You'll be prompted for the service name. Or directly:

```bash
docker compose -p inception -f srcs/docker-compose.yml exec <service_name> <command>
```

Examples:
```bash
# Open bash shell in WordPress container
docker compose -p inception -f srcs/docker-compose.yml exec wordpress /bin/bash

# Check MariaDB status
docker compose -p inception -f srcs/docker-compose.yml exec mariadb mariadb --version

# Verify PHP in WordPress
docker compose -p inception -f srcs/docker-compose.yml exec wordpress php -v
```

### Restart Containers

Restart all:
```bash
make restart
```

Restart specific service:
```bash
docker compose -p inception -f srcs/docker-compose.yml restart <service_name>
```

### Stop Containers

Stop without removing:
```bash
docker compose -p inception -f srcs/docker-compose.yml stop
```

Stop and remove:
```bash
make down
```

---

## Volume Management

### Understanding Volumes

The project uses **Docker named volumes** (not bind mounts) for data persistence:

```yaml
mariadb_data:
  driver: local
  driver_opts:
    type: none
    o: bind
    device: /home/emalungo/data/mariadb

wordpress_data:
  driver: local
  driver_opts:
    type: none
    o: bind
    device: /home/emalungo/data/wordpress
```

### List Volumes

```bash
docker volume ls | grep inception
```

### Inspect Volume

```bash
docker volume inspect inception_mariadb_data
docker volume inspect inception_wordpress_data
```

### View Volume Contents

```bash
ls -la /home/emalungo/data/mariadb/
ls -la /home/emalungo/data/wordpress/
```

### Backup Volumes

#### Backup WordPress Files

```bash
tar -czf wordpress_backup_$(date +%Y%m%d).tar.gz /home/emalungo/data/wordpress/
```

#### Backup Database

```bash
docker compose -p inception -f srcs/docker-compose.yml exec mariadb mysqldump \
  -u root -p${DB_ROOT_PASSWORD} wp_db > db_backup_$(date +%Y%m%d).sql
```

### Restore Volumes

#### Restore WordPress Files

```bash
tar -xzf wordpress_backup_YYYYMMDD.tar.gz -C /
```

#### Restore Database

```bash
docker compose -p inception -f srcs/docker-compose.yml exec -T mariadb mysql \
  -u root -p${DB_ROOT_PASSWORD} wp_db < db_backup_YYYYMMDD.sql
```

### Delete Volumes

⚠️ **Warning**: This deletes all data permanently!

```bash
# Remove specific volumes
docker volume rm inception_wordpress_data inception_mariadb_data

# Or use Makefile
make fclean  # Removes all: containers, volumes, images, networks
```

---

## Data Persistence

### Data Locations

All project data persists in `host:/home/emalungo/data/`:

```
/home/emalungo/data/
├── mariadb/                    # MariaDB database files
│   ├── mysql/                  # System databases
│   ├── performance_schema/      # Performance data
│   └── wp_db/                  # WordPress database
└── wordpress/                  # WordPress application
    ├── wp-admin/               # Admin interface
    ├── wp-content/             # Plugins, themes, uploads
    ├── wp-includes/            # Core WordPress files
    └── wp-config.php           # Configuration file
```

### Verifying Data Persistence

After stopping and restarting containers, verify data is preserved:

```bash
# Stop containers
make down

# Start again
make up

# Check WordPress is still there with previous content
curl -k https://emalungo.42.fr
```

### Database Verification

```bash
docker compose -p inception -f srcs/docker-compose.yml exec wordpress \
  wp db size --allow-root
```

---

## Network Management

### Docker Network

The project uses a custom bridge network for inter-container communication:

```yaml
inception_network:
  driver: bridge
```

### Inspect Network

```bash
docker network inspect inception_network
```

Expected output shows all three containers connected:
- mariadb
- wordpress
- nginx

### Network Communication

Containers communicate using service names as hostnames:

- WordPress connects to MariaDB via: `mysql -h mariadb`
- NGINX proxies requests to WordPress via: `fastcgi_pass wordpress:9000`

### Test Network Connectivity

From WordPress container:

```bash
docker compose -p inception -f srcs/docker-compose.yml exec wordpress \
  mysql -h mariadb -u emalungo -p wp_db -e "SELECT 1;"
```

---

## Troubleshooting Development

### Container Fails to Start

1. Check logs:
   ```bash
   make logs
   ```

2. Look for errors in service initialization scripts (`tools/init.sh`)

3. Verify environment variables:
   ```bash
   docker compose -p inception -f srcs/docker-compose.yml config
   ```

4. Common issues:
   - Port 443 already in use
   - Invalid secrets file paths
   - Insufficient disk space

### Database Won't Initialize

```bash
# Check MariaDB logs
docker compose -p inception -f srcs/docker-compose.yml logs mariadb

# Verify credentials in secrets/
cat secrets/db_password.txt
cat secrets/db_root_password.txt
```

### WordPress Installation Failed

```bash
# Check WordPress logs
docker compose -p inception -f srcs/docker-compose.yml logs wordpress

# Verify MariaDB is reachable
docker compose -p inception -f srcs/docker-compose.yml exec wordpress \
  mysql -h mariadb -u emalungo -p wp_db -e "SELECT 1;"
```

### NGINX Certificate Issues

```bash
# Check certificate generation
docker compose -p inception -f srcs/docker-compose.yml logs nginx

# Verify certificate in NGINX container
docker compose -p inception -f srcs/docker-compose.yml exec nginx \
  ls -la /etc/nginx/ssl/
```

### Permission Denied on Volumes

```bash
# Fix volume ownership
sudo chown -R $USER:$USER /home/emalungo/data/

# Verify permissions
ls -la /home/emalungo/data/
```

---

## Development Workflow

### Making Configuration Changes

1. Edit `.env` or secret files
2. Rebuild affected containers:
   ```bash
   docker compose -p inception -f srcs/docker-compose.yml build --no-cache <service>
   docker compose -p inception -f srcs/docker-compose.yml restart <service>
   ```

3. Verify changes:
   ```bash
   docker compose -p inception -f srcs/docker-compose.yml logs <service>
   ```

### Testing Code Changes

For WordPress theme/plugin development:

1. Files in `/home/emalungo/data/wordpress/wp-content/` are immediately reflected in the running container

2. For PHP/configuration changes, restart the service:
   ```bash
   make restart
   ```

### Debugging with Shell Access

```bash
# Access container shell
docker compose -p inception -p inception -f srcs/docker-compose.yml exec wordpress /bin/bash

# Inside the container, you can:
wp cli version --allow-root
wp db query --allow-root "SELECT * FROM wp_users;"
php -i | grep -A 5 "Configuration File"
```

---

## Full Rebuild Cycle

To completely rebuild the project from scratch:

```bash
# 1. Remove everything
make fclean

# 2. Reconfigure secrets (if needed)
nano secrets/db_password.txt
nano secrets/wp_admin_password.txt
# ... etc

# 3. Rebuild from scratch
make up

# 4. Verify
make ps
curl -k https://emalungo.42.fr
```

---

## Makefile Available Commands

```
make help       # Show all available commands
make up         # Start services (build if needed)
make down       # Stop services
make build      # Build images without starting
make restart    # Restart services
make ps         # Show container status
make logs       # View real-time logs
make shell      # Open shell in container
make clean      # Remove containers and networks
make fclean     # Full clean (volumes, images, networks)
make re         # Rebuild everything (fclean + up)
```

---

## Useful Docker Compose Commands

```bash
# View docker-compose configuration
docker compose -p inception -f srcs/docker-compose.yml config

# Pull images (not used in this project, but for reference)
docker compose -p inception -f srcs/docker-compose.yml pull

# Validate docker-compose.yml
docker compose -p inception -f srcs/docker-compose.yml config --quiet

# View all running processes in containers
docker compose -p inception -f srcs/docker-compose.yml top
```

---

## Development Best Practices

1. **Always check logs** before troubleshooting:
   ```bash
   make logs
   ```

2. **Use named volumes**, not bind mounts, for data persistence

3. **Never hardcode passwords** in Dockerfiles or docker-compose.yml

4. **Test restart policy** by stopping containers:
   ```bash
   docker compose -p inception -f srcs/docker-compose.yml stop
   sleep 5
   make ps  # Containers should auto-restart
   ```

5. **Back up data regularly**:
   ```bash
   tar -czf backup_$(date +%Y%m%d_%H%M%S).tar.gz /home/emalungo/data/
   ```

6. **Document changes** in commit messages

---

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [MariaDB Documentation](https://mariadb.com/docs/)
- [WordPress Docker Setup](https://developer.wordpress.org/plugins/)
- [NGINX Configuration](https://nginx.org/en/docs/)

For user-facing documentation, see **USER_DOC.md**.
For project overview, see **README.md**.
