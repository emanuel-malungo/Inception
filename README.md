# Inception

*This project has been created as part of the 42 curriculum by emalungo.*

---

## Description

**Inception** is a Docker-based system administration project that sets up a complete WordPress infrastructure using containerized services. The project demonstrates proficiency in Docker, container orchestration, networking, and infrastructure as code.

### Project Goal

The objective is to build a multi-container application that provides a fully functional WordPress environment with:
- A secure web server (NGINX) with TLS encryption
- A PHP-FPM application server running WordPress
- A MariaDB database for persistent storage
- Proper networking, volume management, and orchestration using Docker Compose

This project teaches essential DevOps and system administration skills through hands-on Docker implementation.

### Overview

The Inception stack consists of three Docker containers managed as a cohesive unit:

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Web Server** | NGINX | Reverse proxy with TLS (port 443 only) |
| **Application** | WordPress + PHP-FPM | CMS and PHP runtime |
| **Database** | MariaDB | MySQL-compatible data persistence |

All services run on a custom Docker network with persistent data stored in Docker named volumes.

---

## Instructions

### Prerequisites

Before running the project, ensure you have:

- **Docker** (version 20.10+) - [Install Docker](https://docs.docker.com/get-docker/)
- **Docker Compose** (version 2.0+) - [Install Docker Compose](https://docs.docker.com/compose/install/)
- **GNU Make** - Usually pre-installed on Linux/macOS
- **Linux-based system** - Ubuntu, Debian, or Alpine recommended

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url> Inception
   cd Inception
   ```

2. **Create secrets** with secure passwords:
   ```bash
   mkdir -p secrets
   echo "secure_password_1" > secrets/db_password.txt
   echo "secure_password_2" > secrets/db_root_password.txt
   echo "secure_password_3" > secrets/wp_admin_password.txt
   echo "secure_password_4" > secrets/wp_editor_password.txt
   chmod 600 secrets/*.txt
   ```

3. **Configure environment variables** in `srcs/.env`:
   ```bash
   DOMAIN_NAME=emalungo.42.fr
   MYSQL_USER=emalungo
   MYSQL_DATABASE=wp_db
   DB_HOST=mariadb
   WP_TITLE=Inception
   WP_ADMIN_USER=emanuelmalungo
   WP_ADMIN_EMAIL=emanuelmalungo@intra.42.fr
   WP_EDITOR_USER=emalungo
   WP_EDITOR_EMAIL=emalungo@intra.42.fr
   ```

4. **Add domain to `/etc/hosts`**:
   ```bash
   echo "127.0.0.1 emalungo.42.fr" | sudo tee -a /etc/hosts
   ```

### Compilation & Building

Build the Docker images:

```bash
make build
```

This compiles custom Dockerfiles for NGINX, WordPress, and MariaDB.

### Execution

Start all services in background:

```bash
make up
```

This command automatically creates volumes, builds images, and starts containers.

### Accessing the Application

Once running, access the infrastructure:

- **Website**: https://emalungo.42.fr
- **WordPress Admin**: https://emalungo.42.fr/wp-admin
- **Administrator Username**: `emanuelmalungo`
- **Administrator Password**: See `secrets/wp_admin_password.txt`

### Managing the Stack

**View status**:
```bash
make ps
```

**View real-time logs**:
```bash
make logs
```

**Stop services**:
```bash
make down
```

**Restart services**:
```bash
make restart
```

**Full rebuild** (removes all volumes and images):
```bash
make re
```

For detailed instructions, see:
- **USER_DOC.md** - End-user and administrator guide
- **DEV_DOC.md** - Developer setup and operations guide

---

## Project Description

### Docker Architecture

The Inception project demonstrates modern containerization practices using Docker Compose to orchestrate three independent services.

#### Directory Structure

```
Inception/
├── Makefile                         # Automation and orchestration
├── README.md                        # Project documentation
├── docs/
│   ├── USER_DOC.md                 # User and admin guide
│   └── DEV_DOC.md                  # Developer guide
├── secrets/                         # Sensitive credentials (not in git)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_editor_password.txt
└── srcs/
    ├── docker-compose.yml          # Service orchestration
    ├── .env                        # Environment variables
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── my.cnf
        │   └── tools/
        │       └── init.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── nginx.conf.template
        │   └── tools/
        │       └── run.sh
        └── wordpress/
            ├── Dockerfile
            ├── .dockerignore
            ├── conf/
            │   └── www.conf
            └── tools/
                └── init.sh
```

#### Services

**1. MariaDB** (Database)
- Base image: `debian:bookworm` (penultimate stable version)
- Port: 3306 (internal only, not exposed)
- Volumes: `/var/lib/mysql` persistently stored
- Initialization: Custom SQL setup with two database users
- Restart policy: `unless-stopped`

**2. WordPress + PHP-FPM** (Application)
- Base image: `debian:bookworm`
- Port: 9000 (FastCGI protocol, not exposed)
- PHP version: 8.2
- Volumes: `/var/www/html` for website files
- Dependencies: Waits for MariaDB before starting
- Initialization: Automated WordPress installation via WP-CLI
- Restart policy: `unless-stopped`

**3. NGINX** (Web Server)
- Base image: `debian:bookworm`
- Port: 443 (HTTPS only, TLSv1.2/TLSv1.3)
- Features: Reverse proxy to PHP-FPM, TLS certificate generation, domain-based routing
- Volumes: Shares WordPress files with application container
- Restart policy: `unless-stopped`

#### Networking

All services communicate through a custom Docker bridge network (`inception_network`):
- Service discovery via container names (e.g., `mariadb`, `wordpress`)
- No external network exposure except NGINX port 443
- Secure internal communication without network: host

#### Data Persistence

Data is persisted using **Docker named volumes** mounted to the host:

```yaml
Volumes:
  mariadb_data:
    Mount point: /var/lib/mysql
    Host location: /home/emalungo/data/mariadb

  wordpress_data:
    Mount point: /var/www/html
    Host location: /home/emalungo/data/wordpress
```

Advantages of named volumes over bind mounts:
- Better performance
- Managed by Docker (automatic cleanup)
- Platform-independent
- Can be backed up and migrated easily

### Design Choices

#### 1. **Why Debian over Alpine?**
- **Chosen: Debian:bookworm** (penultimate stable version per project requirements)
- Larger base image but better compatibility with complex applications
- More familiar to developers and administrators
- Better package ecosystem for MariaDB and PHP

#### 2. **Why Docker Compose?**
- Declarative infrastructure as code
- Single command (`make up`) to orchestrate entire stack
- Easy to version control and reproduce
- Built-in networking and volume management

#### 3. **HTTPS-Only (Port 443)**
- Port 80 explicitly disabled
- Self-signed TLS certificates auto-generated per domain
- Ensures encrypted communication in development environment
- Follows modern security best practices

#### 4. **Separate Services vs Monolith**
- **Decision**: Three separate containers
- **Benefits**:
  - Independent scaling and updates
  - Better isolation and security
  - Clear separation of concerns
  - Easier debugging and maintenance

### Comparisons

#### Virtual Machines vs Docker

| Aspect | Virtual Machine | Docker Container |
|--------|-----------------|------------------|
| **Overhead** | Heavy (full OS per VM) | Lightweight (shared kernel) |
| **Startup Time** | Minutes | Seconds |
| **Resource Usage** | GB of RAM per VM | MB per container |
| **Portability** | Hypervisor-dependent | Works on any Docker host |
| **Isolation** | Complete OS isolation | Process-level isolation |
| **Use Case** | Full OS needed | Application containerization |

**Inception uses Docker** because:
- Rapid development iteration
- Minimal resource consumption
- Perfect reproducibility across environments
- Suitable for application not OS deployment

#### Secrets vs Environment Variables

| Method | Storage | Security | Use Case |
|--------|---------|----------|----------|
| **Secrets** | Docker Secrets (encrypted) | High (not in images) | Passwords, API keys, tokens |
| **Environment Variables** | In memory/`.env` file | Medium (visible in configs) | Non-sensitive config (domain, ports) |

**Inception Implementation**:
- **Secrets**: Passwords stored in `secrets/*.txt` files (encrypted at runtime)
- **Environment Variables**: Domain names, usernames, non-sensitive config in `.env`
- **Never**: Hardcoded passwords in Dockerfiles or images

**Why this matters**: Credentials in Git repositories → immediate project failure

#### Docker Network vs Host Network

| Type | Isolation | Use Case | Inception Choice |
|------|-----------|----------|------------------|
| **Bridge Network** | Containers isolated from host | Secure inter-container communication | ✅ Used |
| **Host Network** | No isolation (container sees host network) | Performance-critical apps | ❌ Not allowed by project |
| **Overlay Network** | Swarm/K8s multi-host | Distributed systems | Not applicable |

**Inception uses Bridge Network** because:
- Containers can't directly access host ports
- Services communicate by container names
- NGINX is the only entry point (port 443)
- Greater security and isolation

#### Docker Volumes vs Bind Mounts

| Type | Management | Performance | Inception Choice |
|------|-----------|-------------|------------------|
| **Named Volumes** | Docker-managed | Optimized for containers | ✅ Used for persistence |
| **Bind Mounts** | Host path mounted | Direct filesystem access | ❌ Not allowed by project |
| **tmpfs** | In-memory only | Very fast, temporary | Not applicable |

**Inception uses Named Volumes** because:
- Easier to backup and migrate
- Better performance (especially on non-Linux hosts)
- Platform-independent
- Automatic Docker management
- Consistent behavior across environments

### Key Technical Decisions

1. **PID 1 Handling**: Services use `exec` in entrypoint scripts to become PID 1, ensuring proper signal handling and graceful shutdowns
2. **No Infinite Loops**: All scripts are structured as daemons that run once, not as loops (no `tail -f`, `sleep infinity`, or `while true`)
3. **Health Checks**: Containers use proper daemon management; no polling or hacky workarounds
4. **Environment Variables**: All configuration is externalized; no hardcoded values in images
5. **Restart Policy**: `unless-stopped` allows automatic recovery from crashes while respecting manual stops

---

## Resources

### Official Documentation

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [MariaDB Official Docs](https://mariadb.com/docs/)
- [WordPress Installation Guide](https://wordpress.org/support/article/how-to-install-wordpress/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.php)

### Learning Resources

- [Docker in 100 Seconds](https://www.youtube.com/watch?v=Gjmp7xt9-2g)
- [Docker Networking Deep Dive](https://docs.docker.com/network/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [Understanding Container Basics](https://www.youtube.com/watch?v=oO8n3-4f6So)
- [42 School Docker Tutorials](https://github.com/42School/42-Cursus) (internal resource)

### Related Projects

- [42's ft_transcendence](https://github.com/42School) - Advanced Docker usage
- [docker-compose examples](https://github.com/docker/awesome-compose)

---

## AI Usage

This project was developed using AI assistance for specific tasks while maintaining full understanding and responsibility for all code and configurations.

### Tasks Enhanced by AI

#### 1. **Dockerfile Optimization** (25% AI-assisted)
- **What AI helped with**: Suggesting Dockerfile best practices, RUN command optimization, multi-stage builds
- **What was manual**: Understanding the specific requirements, debugging Docker build errors, testing image compatibility
- **Result**: Optimized Dockerfiles with minimal layers and fast builds

#### 2. **Docker Compose Configuration** (20% AI-assisted)
- **What AI helped with**: Syntax validation, volume structure recommendations, networking setup patterns
- **What was manual**: Designing the architecture, understanding dependency order, implementing health checks
- **Result**: Clean, modular docker-compose.yml with proper service dependencies

#### 3. **Bash Scripts (init.sh, run.sh)** (30% AI-assisted)
- **What AI helped with**: Shell syntax suggestions, common patterns for database initialization, signal handling
- **What was manual**: Understanding MariaDB initialization, WordPress WP-CLI, debugging script execution
- **Result**: Robust initialization scripts with proper error handling and PID 1 management

#### 4. **Documentation** (40% AI-assisted)
- **What AI helped with**: Structure templates, formatting, comprehensive section generation
- **What was manual**: Content accuracy, specific project configuration details, technical verification
- **Result**: Complete, clear documentation in USER_DOC.md, DEV_DOC.md, README.md

### AI Limitations Encountered

1. **Generic Responses**: AI provided generic Docker examples that needed project-specific adaptation
2. **Security Concerns**: AI initially suggested environment-based secrets; corrected to Docker Secrets for compliance
3. **Debian vs Alpine**: AI suggested Alpine by default; actively chose Debian per project requirements
4. **No Loop-Based Solutions**: AI initially suggested `tail -f` patterns which were explicitly forbidden
5. **Volume Structure**: Generic advice didn't account for the specific `/home/emalungo/data/` requirement

### Critical Understanding

All code has been thoroughly reviewed, tested, and is fully understood. During peer evaluation, I can explain:
- Why each Docker service is structured as it is
- The purpose of every environment variable and secret
- How the networking and volume management works
- The initialization sequence and dependency order
- How to troubleshoot and modify any component

---

## Project Status

### Mandatory Requirements

- ✅ Full Docker Compose infrastructure
- ✅ Three dedicated containers (NGINX, WordPress, MariaDB)
- ✅ TLS 1.2/1.3 only on port 443
- ✅ Custom Dockerfiles (no pulled images except base OS)
- ✅ Docker named volumes with persistence
- ✅ Docker secrets for password management
- ✅ Custom Docker network
- ✅ Restart policies configured
- ✅ No hacky patches (proper daemon management)
- ✅ Environment variable configuration
- ✅ Makefile automation
- ✅ Documentation (README, USER_DOC, DEV_DOC)

### Testing

To verify the installation works:

```bash
# Start the stack
make up

# Check services are running
make ps

# Access the website
curl -k https://emalungo.42.fr

# Verify database connection
docker compose -p inception exec wordpress mysql -h mariadb -u emalungo -p wp_db -e "SELECT 1;"
```

---

## Author

- **emalungo** - 42 School Student

## License

This project is part of the 42 Cursus and follows the school's project guidelines.

---

## Contributing

As this is a 42 Cursus project, contributions are limited to the original author. For feedback or suggestions, please contact through 42's internal channels.

---

**Last Updated**: April 2026  
**Project Version**: 1.0
