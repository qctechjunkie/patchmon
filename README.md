# PatchMon Docker Compose Setup

This repository contains a Docker Compose configuration for running PatchMon, a patch monitoring and management system.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Security Features](#security-features)
- [Management](#management)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)

## Prerequisites

- Docker Engine 20.10 or later
- Docker Compose V2
- At least 2GB of free RAM
- OpenSSL (for generating secure passwords)

## Quick Start

### 1. Clone and Configure

```bash
# Navigate to the directory
cd patchmon

# Copy the example environment file
cp .env.example .env
```

### 2. Generate Secure Credentials

Generate strong passwords and secrets for your deployment:

```bash
# Generate PostgreSQL password
openssl rand -hex 64

# Generate Redis password
openssl rand -hex 64

# Generate JWT secret
openssl rand -hex 64
```

### 3. Edit Configuration

Open `.env` in your text editor and update the following required values:

```bash
# Database Configuration
POSTGRES_PASSWORD=<paste-generated-postgres-password>

# Redis Configuration
REDIS_PASSWORD=<paste-generated-redis-password>

# Backend Configuration
JWT_SECRET=<paste-generated-jwt-secret>

# Server Configuration
SERVER_HOST=<your-server-ip-or-domain>
SERVER_PORT=3001
CORS_ORIGIN=<your-frontend-url>
```

**Important Configuration Notes:**

- `SERVER_HOST`: The IP address or domain where PatchMon will be accessible (used by agents to connect)
- `SERVER_PORT`: The port where the frontend will be exposed (default: 3001)
- `CORS_ORIGIN`: The full URL where you'll access the frontend (e.g., `https://patchmon.example.com` or `http://192.168.1.100:3001`)
- `SERVER_PROTOCOL`: Use `https` if behind a reverse proxy with SSL, otherwise `http`

### 4. Start the Stack

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Check service status
docker compose ps
```

### 5. Access PatchMon

Once all services are healthy, access PatchMon at:
- `http://<SERVER_HOST>:<SERVER_PORT>` (or your configured CORS_ORIGIN)

## Configuration

### Environment Variables

The `.env` file contains all configuration. Key sections:

#### Database Settings
```bash
POSTGRES_DB=patchmon_db           # Database name
POSTGRES_USER=patchmon_user       # Database user
POSTGRES_PASSWORD=<generated>     # Database password (CHANGE THIS)
```

#### Redis Settings
```bash
REDIS_PASSWORD=<generated>        # Redis password (CHANGE THIS)
REDIS_HOST=redis                  # Redis hostname (usually 'redis')
REDIS_PORT=6379                   # Redis port
REDIS_DB=0                        # Redis database number
```

#### Backend Settings
```bash
JWT_SECRET=<generated>            # JWT signing secret (CHANGE THIS)
LOG_LEVEL=info                    # Logging level (debug, info, warn, error)
```

#### Server Settings
```bash
SERVER_PROTOCOL=http              # Protocol for agent connections (http/https)
SERVER_HOST=192.168.1.100         # Your server IP or domain
SERVER_PORT=3001                  # Port for frontend access
CORS_ORIGIN=http://192.168.1.100:3001  # Frontend URL for CORS
```

#### Resource Limits

Adjust based on your system resources:

```bash
BACKEND_MEMORY_LIMIT=512m         # Backend container memory limit
BACKEND_MEMORY_RESERVATION=256m   # Backend guaranteed memory
FRONTEND_MEMORY_LIMIT=256m        # Frontend container memory limit
FRONTEND_MEMORY_RESERVATION=128m  # Frontend guaranteed memory
POSTGRES_MEMORY_LIMIT=512m        # Database memory limit
POSTGRES_MEMORY_RESERVATION=256m  # Database guaranteed memory
REDIS_MEMORY_LIMIT=256m           # Redis memory limit
REDIS_MEMORY_RESERVATION=128m     # Redis guaranteed memory
```

## Security Features

This Docker Compose configuration implements several security best practices:

### 1. Secrets Management
- All sensitive data stored in `.env` file
- `.env` excluded from git via `.gitignore`
- No hardcoded credentials in `compose.yaml`
- `.env.example` provided as template (no sensitive data)

### 2. Network Isolation
- **patchmon-internal**: Internal network for database and Redis (no external access)
- **patchmon-frontend**: Network for frontend-backend communication
- Database and Redis are not exposed to the host

### 3. Resource Limits
- Memory limits prevent resource exhaustion
- Memory reservations ensure minimum resources
- Redis has maxmemory policy configured

### 4. Security Options
- `no-new-privileges` prevents privilege escalation
- Container-specific security options applied

### 5. Health Checks
- All services have health checks
- Dependent services wait for health before starting
- Automatic restart on failure

### 6. Minimal Attack Surface
- Alpine-based images (smaller attack surface)
- Only frontend port exposed to host
- Internal services isolated

## Management

### Starting and Stopping

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Stop and remove volumes (WARNING: deletes all data)
docker compose down -v
```

### Viewing Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f backend
docker compose logs -f database
docker compose logs -f redis
docker compose logs -f frontend
```

### Updating Services

```bash
# Pull latest images
docker compose pull

# Recreate containers with new images
docker compose up -d

# Remove old images
docker image prune
```

### Backing Up Data

```bash
# Backup PostgreSQL database
docker compose exec database pg_dump -U patchmon_user patchmon_db > backup.sql

# Backup volumes (while services are stopped)
docker compose down
sudo tar -czf patchmon-volumes-backup.tar.gz /var/lib/docker/volumes/patchmon_*
docker compose up -d
```

### Restoring Data

```bash
# Restore PostgreSQL database
docker compose exec -T database psql -U patchmon_user patchmon_db < backup.sql
```

## Troubleshooting

### Services Won't Start

Check service health:
```bash
docker compose ps
docker compose logs
```

### Connection Issues

Verify network connectivity:
```bash
# Check if backend can reach database
docker compose exec backend ping database

# Check if backend can reach redis
docker compose exec backend ping redis
```

### Permission Issues

Ensure proper permissions on volumes:
```bash
# Fix volume permissions (Linux)
sudo chown -R 999:999 /var/lib/docker/volumes/patchmon_postgres_data
sudo chown -R 999:999 /var/lib/docker/volumes/patchmon_redis_data
```

### Memory Issues

If containers are killed due to OOM:
1. Increase resource limits in `.env`
2. Increase host system memory
3. Check for memory leaks in logs

### Database Connection Errors

Verify DATABASE_URL is correct:
```bash
docker compose exec backend env | grep DATABASE_URL
```

The URL should match: `postgresql://patchmon_user:<POSTGRES_PASSWORD>@database:5432/patchmon_db`

### Redis Connection Errors

Verify Redis password:
```bash
docker compose exec backend env | grep REDIS_PASSWORD
```

Test Redis connection:
```bash
docker compose exec redis redis-cli -a <REDIS_PASSWORD> ping
```

## Advanced Configuration

### Using Behind a Reverse Proxy

If running behind Nginx or Traefik:

1. Set in `.env`:
```bash
SERVER_PROTOCOL=https
SERVER_HOST=patchmon.example.com
CORS_ORIGIN=https://patchmon.example.com
```

2. Configure your reverse proxy to forward to `localhost:3001`

### Customizing Rate Limits

Adjust in `.env`:
```bash
# General API rate limit (15 minutes = 900000ms)
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX=5000

# Authentication rate limit (10 minutes)
AUTH_RATE_LIMIT_WINDOW_MS=600000
AUTH_RATE_LIMIT_MAX=500

# Agent rate limit (1 minute)
AGENT_RATE_LIMIT_WINDOW_MS=60000
AGENT_RATE_LIMIT_MAX=1000
```

### Database Connection Pooling

Tune for your workload in `.env`:
```bash
DB_CONNECTION_LIMIT=30      # Max connections
DB_POOL_TIMEOUT=20          # Pool timeout (seconds)
DB_CONNECT_TIMEOUT=10       # Connect timeout (seconds)
DB_IDLE_TIMEOUT=300         # Idle timeout (seconds)
DB_MAX_LIFETIME=1800        # Max connection lifetime (seconds)
```

### Custom Port Binding

To use a different port:
```bash
# In .env
SERVER_PORT=8080
```

The frontend will be accessible at `http://<SERVER_HOST>:8080`

## Support

For issues and questions:
- PatchMon Documentation: [Link to docs]
- Issue Tracker: [Link to issues]
- Community Forum: [Link to forum]

## License

[Your License Here]
