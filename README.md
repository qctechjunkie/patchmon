# PatchMon Docker Compose Setup

This repository contains a Docker Compose configuration for running PatchMon, a patch monitoring and management system.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Raspberry Pi 5 Optimization](#raspberry-pi-5-optimization)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Security Features](#security-features)
- [Management](#management)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)

## Prerequisites

- Docker Engine 20.10 or later
- Docker Compose V2
- At least 2GB of free RAM (4GB+ recommended for Raspberry Pi)
- OpenSSL (for generating secure passwords)

### For Raspberry Pi 5

- Raspberry Pi OS (64-bit) - Bookworm or later
- Raspberry Pi 5 with 4GB or 8GB RAM
- MicroSD card (Class 10 or better) or NVMe SSD for better performance
- Proper cooling (heatsink or active cooling recommended)

## Raspberry Pi 5 Optimization

This configuration is **optimized for Raspberry Pi 5** with conservative resource limits suitable for 4-8GB RAM models.

### Why Raspberry Pi 5?

The Pi 5 is an excellent platform for PatchMon due to:
- ARM64 architecture support (all images are multi-arch)
- Sufficient RAM (4-8GB) for running the full stack
- Low power consumption (3-5W typical)
- Quiet, fanless operation with proper heatsink
- Always-on capability for 24/7 monitoring

### Performance Tips for Raspberry Pi

1. **Use SSD Storage**: NVMe SSD via M.2 HAT provides 5-10x better performance than SD card
2. **Enable Swap**: Add 2GB swap for stability
   ```bash
   sudo dphys-swapfile swapoff
   sudo nano /etc/dphys-swapfile  # Set CONF_SWAPSIZE=2048
   sudo dphys-swapfile setup
   sudo dphys-swapfile swapon
   ```

3. **Cooling**: Ensure proper cooling to prevent thermal throttling
   ```bash
   # Check temperature
   vcgencmd measure_temp

   # Monitor throttling
   vcgencmd get_throttled
   ```

4. **Boot from SSD**: Boot from NVMe for best performance
5. **Disable unnecessary services**: Free up RAM and CPU
   ```bash
   sudo systemctl disable bluetooth
   sudo systemctl disable cups
   ```

### Resource Allocation for Pi

The default `.env` file includes optimized limits:

```bash
# For Pi 5 with 4GB RAM (default)
BACKEND_MEMORY_LIMIT=384m
POSTGRES_MEMORY_LIMIT=384m
FRONTEND_MEMORY_LIMIT=192m
REDIS_MEMORY_LIMIT=128m

# For Pi 5 with 8GB RAM (can increase 30-50%)
BACKEND_MEMORY_LIMIT=512m
POSTGRES_MEMORY_LIMIT=512m
FRONTEND_MEMORY_LIMIT=256m
REDIS_MEMORY_LIMIT=192m
```

Total memory usage: ~1.1GB (4GB model) or ~1.5GB (8GB model), leaving plenty for system and other services.

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

**Default values are optimized for Raspberry Pi 5:**

```bash
# Raspberry Pi 5 (4GB RAM) - Default values
BACKEND_MEMORY_LIMIT=384m         # Backend container memory limit
BACKEND_MEMORY_RESERVATION=192m   # Backend guaranteed memory
FRONTEND_MEMORY_LIMIT=192m        # Frontend container memory limit
FRONTEND_MEMORY_RESERVATION=96m   # Frontend guaranteed memory
POSTGRES_MEMORY_LIMIT=384m        # Database memory limit
POSTGRES_MEMORY_RESERVATION=192m  # Database guaranteed memory
REDIS_MEMORY_LIMIT=128m           # Redis memory limit
REDIS_MEMORY_RESERVATION=64m      # Redis guaranteed memory
```

**For Pi 5 with 8GB RAM**, increase limits by 30-50%:
```bash
BACKEND_MEMORY_LIMIT=512m
POSTGRES_MEMORY_LIMIT=512m
FRONTEND_MEMORY_LIMIT=256m
REDIS_MEMORY_LIMIT=192m
```

**For x86_64 servers**, you can double or triple these values.

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

### Raspberry Pi Specific Issues

#### Slow Performance

1. **Check SD card health**: SD cards can degrade over time
   ```bash
   # Test write speed
   dd if=/dev/zero of=test.img bs=1M count=1024 conv=fdatasync
   rm test.img
   ```
   Should be >20 MB/s for Class 10. Consider upgrading to SSD if slower.

2. **Monitor temperature and throttling**:
   ```bash
   # Current temperature
   vcgencmd measure_temp

   # Check throttling status (should return 0x0)
   vcgencmd get_throttled
   ```
   If throttled (not 0x0), improve cooling or reduce load.

3. **Check memory usage**:
   ```bash
   free -h
   docker stats
   ```

4. **Enable logging to RAM** (reduces SD card writes):
   ```bash
   sudo nano /etc/fstab
   # Add: tmpfs /var/log tmpfs defaults,noatime,size=100m 0 0
   sudo mount -a
   ```

#### Architecture Issues

All PatchMon images support ARM64. If you see architecture errors:
```bash
# Verify Docker is using ARM64
docker version

# Check image architecture
docker image inspect ghcr.io/patchmon/patchmon-backend:latest | grep Architecture
```

#### Out of Memory Errors

If containers are killed by OOM:
1. Check total memory usage: `docker stats`
2. Reduce resource limits in `.env`
3. Enable more swap space (see [Performance Tips](#performance-tips-for-raspberry-pi))
4. Close unnecessary applications

#### Slow Database Queries

If database performance is poor:
1. Reduce `DB_CONNECTION_LIMIT` to 15-20 in `.env`
2. Increase `POSTGRES_MEMORY_LIMIT` if RAM available
3. Consider moving to SSD storage
4. Run database maintenance:
   ```bash
   docker compose exec database psql -U patchmon_user -d patchmon_db -c "VACUUM ANALYZE;"
   ```

#### Network Issues

If agents can't connect:
1. Verify firewall allows traffic on `SERVER_PORT`
   ```bash
   sudo ufw status
   sudo ufw allow 3001/tcp
   ```

2. Check Pi's IP address hasn't changed
   ```bash
   hostname -I
   ```

3. If using WiFi, consider ethernet for stability

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
# Raspberry Pi 5 (4GB) - Default
DB_CONNECTION_LIMIT=20      # Max connections

# Raspberry Pi 5 (8GB) or more powerful systems
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

### Monitoring Raspberry Pi Performance

Create a simple monitoring script for your Pi:

```bash
#!/bin/bash
# Save as monitor-pi.sh

echo "=== Raspberry Pi 5 Status ==="
echo "Temperature: $(vcgencmd measure_temp)"
echo "Throttling: $(vcgencmd get_throttled)"
echo ""
echo "=== Memory Usage ==="
free -h
echo ""
echo "=== Docker Container Stats ==="
docker stats --no-stream
echo ""
echo "=== Disk Usage ==="
df -h | grep -E '/$|/boot'
```

Make it executable and run:
```bash
chmod +x monitor-pi.sh
./monitor-pi.sh
```

For continuous monitoring, consider installing:
```bash
# Htop for system monitoring
sudo apt install htop

# Glances for more detailed monitoring
sudo apt install glances
```

## Support

For issues and questions:
- PatchMon Documentation: [Link to docs]
- Issue Tracker: [Link to issues]
- Community Forum: [Link to forum]

## License

[Your License Here]
