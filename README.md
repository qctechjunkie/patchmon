# PatchMon Docker Compose Setup

This repository contains a Docker Compose configuration for running PatchMon on Raspberry Pi 5.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Running PatchMon](#running-patchmon)
- [Management](#management)
- [Troubleshooting](#troubleshooting)
- [Security Best Practices](#security-best-practices)

## Prerequisites

- Docker Engine 20.10 or later
- Docker Compose V2
- Raspberry Pi 5 with 4GB or 8GB RAM recommended
- OpenSSL (for generating secure passwords)

## Quick Start

### 1. Copy Environment File

```bash
cp .env.example .env
```

### 2. Generate Secure Passwords

Generate three secure passwords/secrets:

```bash
# Generate PostgreSQL password
openssl rand -hex 64

# Generate Redis password
openssl rand -hex 64

# Generate JWT secret
openssl rand -hex 64
```

### 3. Configure Environment Variables

Edit the `.env` file and update the following **required** values:

```bash
# Update these with the generated passwords
POSTGRES_PASSWORD=<paste-first-generated-password>
REDIS_PASSWORD=<paste-second-generated-password>
JWT_SECRET=<paste-third-generated-password>

# Update these with your server details
SERVER_HOST=<your-raspberry-pi-ip-address>
CORS_ORIGIN=<full-url-to-access-patchmon>
```

**Example Configuration:**

```bash
POSTGRES_PASSWORD=b33b8035de1a0d1321f21f5b90a8a47532c266add6f41877a015bc5c976d4aee
REDIS_PASSWORD=32c500d1487d8b43ccdba55fc12cd7e749c2b5f181a0c162d36e186316b55cdd
JWT_SECRET=a18e6f2a0dbf149da785c30911b53e4b3657f0bb9b35fd687252072f8c926553
SERVER_HOST=192.168.1.100
CORS_ORIGIN=http://192.168.1.100:3001
```

### 4. Start PatchMon

```bash
docker compose up -d
```

### 5. Verify Services

```bash
# Check if all services are running
docker compose ps

# View logs
docker compose logs -f
```

### 6. Access PatchMon

Once all services are healthy, access PatchMon at:
- **URL**: `http://<SERVER_HOST>:<SERVER_PORT>` (default: port 3001)

## Configuration

All configuration is managed through the `.env` file. Here are the key settings:

### Database Settings

```bash
POSTGRES_DB=patchmon_db          # Database name (usually no need to change)
POSTGRES_USER=patchmon_user      # Database user (usually no need to change)
POSTGRES_PASSWORD=<your-password> # CHANGE THIS - Use generated password
```

### Redis Settings

```bash
REDIS_PASSWORD=<your-password>   # CHANGE THIS - Use generated password
REDIS_HOST=redis                 # Redis hostname (don't change)
REDIS_PORT=6379                  # Redis port (don't change)
REDIS_DB=0                       # Redis database number (don't change)
```

### Backend/JWT Settings

```bash
JWT_SECRET=<your-secret>         # CHANGE THIS - Use generated secret
LOG_LEVEL=info                   # Logging level: debug, info, warn, error
```

### Server Settings

```bash
# Protocol agents use to connect (http or https)
SERVER_PROTOCOL=http

# Your Raspberry Pi's IP address or domain name
SERVER_HOST=192.168.1.100

# Port where PatchMon frontend will be accessible
SERVER_PORT=3001

# Full URL for CORS (must match how you access PatchMon)
CORS_ORIGIN=http://192.168.1.100:3001
```

**Important Notes:**
- `SERVER_HOST`: Should be the IP address or domain name that agents will use to connect
- `CORS_ORIGIN`: Must be the full URL (including protocol and port) where you'll access the frontend
- If using a reverse proxy with SSL, set `SERVER_PROTOCOL=https` and update `CORS_ORIGIN` accordingly

### Database Connection Pool

Default values work well for Raspberry Pi 5:

```bash
DB_CONNECTION_LIMIT=30           # Maximum database connections
DB_POOL_TIMEOUT=20               # Pool timeout in seconds
DB_CONNECT_TIMEOUT=10            # Connection timeout in seconds
DB_IDLE_TIMEOUT=300              # Idle connection timeout
DB_MAX_LIFETIME=1800             # Maximum connection lifetime
```

For Raspberry Pi 4GB model, consider reducing `DB_CONNECTION_LIMIT` to 20.

### Rate Limiting

Configure rate limits to protect your server:

```bash
# General API rate limit (15 minutes)
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX=5000

# Authentication rate limit (10 minutes)
AUTH_RATE_LIMIT_WINDOW_MS=600000
AUTH_RATE_LIMIT_MAX=500

# Agent rate limit (1 minute)
AGENT_RATE_LIMIT_WINDOW_MS=60000
AGENT_RATE_LIMIT_MAX=1000
```

## Running PatchMon

### Start All Services

```bash
docker compose up -d
```

### Stop All Services

```bash
docker compose down
```

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f backend
docker compose logs -f database
docker compose logs -f redis
docker compose logs -f frontend
```

### Restart Services

```bash
# Restart all services
docker compose restart

# Restart specific service
docker compose restart backend
```

## Management

### Updating PatchMon

```bash
# Pull latest images
docker compose pull

# Recreate containers with new images
docker compose up -d

# Remove old images
docker image prune -f
```

### Backing Up Data

#### Backup Database

```bash
docker compose exec database pg_dump -U patchmon_user patchmon_db > backup-$(date +%Y%m%d).sql
```

#### Restore Database

```bash
docker compose exec -T database psql -U patchmon_user patchmon_db < backup-20241030.sql
```

#### Backup Volumes (Full Backup)

```bash
# Stop services first
docker compose down

# Backup volumes
sudo tar -czf patchmon-backup-$(date +%Y%m%d).tar.gz \
  /var/lib/docker/volumes/patchmon_postgres_data \
  /var/lib/docker/volumes/patchmon_redis_data \
  /var/lib/docker/volumes/patchmon_agent_files

# Start services
docker compose up -d
```

### Monitoring

#### Check Container Status

```bash
# View running containers
docker compose ps

# View resource usage
docker stats
```

#### Check Service Health

```bash
# All services
docker compose ps

# Specific service logs
docker compose logs backend --tail 100
```

#### Raspberry Pi Monitoring

```bash
# Check temperature
vcgencmd measure_temp

# Check for throttling (should be 0x0)
vcgencmd get_throttled

# Check memory usage
free -h

# Check disk space
df -h
```

## Troubleshooting

### Services Won't Start

Check the logs for errors:

```bash
docker compose logs
```

Common issues:
- **Port already in use**: Change `SERVER_PORT` in `.env`
- **Environment variables not loading**: Ensure `.env` file exists in the same directory as `compose.yaml`
- **Permission errors**: Check file permissions on volumes

### Database Connection Errors

Verify the `DATABASE_URL` is being constructed correctly:

```bash
docker compose exec backend env | grep DATABASE_URL
```

Should show: `postgresql://patchmon_user:<password>@database:5432/patchmon_db`

### Redis Connection Errors

Test Redis connection:

```bash
# Get Redis password from .env
docker compose exec redis redis-cli -a <REDIS_PASSWORD> ping
```

Should return: `PONG`

### Container Keeps Restarting

Check the container logs:

```bash
docker compose logs <service-name>
```

Check if the service is healthy:

```bash
docker compose ps
```

### Out of Memory (OOM) Issues

Raspberry Pi 5 should handle PatchMon well, but if you experience OOM:

1. Check memory usage:
   ```bash
   free -h
   docker stats
   ```

2. Reduce database connections in `.env`:
   ```bash
   DB_CONNECTION_LIMIT=20
   ```

3. Enable swap if not already enabled:
   ```bash
   sudo dphys-swapfile swapoff
   sudo nano /etc/dphys-swapfile  # Set CONF_SWAPSIZE=2048
   sudo dphys-swapfile setup
   sudo dphys-swapfile swapon
   ```

### Slow Performance

1. **Check SD card vs SSD**: NVMe SSD provides much better performance
2. **Check temperature**: High temps cause throttling
   ```bash
   vcgencmd measure_temp
   ```
3. **Check for throttling**:
   ```bash
   vcgencmd get_throttled
   ```
   If not `0x0`, improve cooling or reduce load

### Network Issues

If agents can't connect:

1. Verify `SERVER_HOST` in `.env` matches your Pi's IP:
   ```bash
   hostname -I
   ```

2. Check firewall settings:
   ```bash
   sudo ufw status
   sudo ufw allow 3001/tcp
   ```

3. Test connectivity from agent machine:
   ```bash
   curl http://<SERVER_HOST>:<SERVER_PORT>
   ```

## Security Best Practices

###  Implemented

- **Environment Variables**: All sensitive data stored in `.env` (not in git)
- **Strong Passwords**: Use 64-character hex passwords generated with `openssl rand -hex 64`
- **Git Protection**: `.env` is excluded via `.gitignore`

### = Additional Recommendations

1. **Firewall**: Only expose necessary ports
   ```bash
   sudo ufw enable
   sudo ufw allow ssh
   sudo ufw allow 3001/tcp  # PatchMon port
   ```

2. **Regular Updates**: Keep Docker and system updated
   ```bash
   sudo apt update && sudo apt upgrade -y
   docker compose pull
   docker compose up -d
   ```

3. **Backup Regularly**: Schedule automatic backups
   ```bash
   # Add to crontab
   0 2 * * * cd /path/to/patchmon && docker compose exec database pg_dump -U patchmon_user patchmon_db > backup-$(date +\%Y\%m\%d).sql
   ```

4. **Reverse Proxy**: Use Nginx or Traefik with SSL for production
5. **Network Isolation**: Keep PatchMon on a separate VLAN if possible
6. **Monitor Logs**: Regularly check logs for suspicious activity

## Advanced Configuration

### Using with Reverse Proxy (Nginx/Traefik)

If running behind a reverse proxy with SSL:

1. Update `.env`:
   ```bash
   SERVER_PROTOCOL=https
   SERVER_HOST=patchmon.example.com
   CORS_ORIGIN=https://patchmon.example.com
   ```

2. Configure reverse proxy to forward to `localhost:3001`

### Custom Port

To use a different port, update `.env`:

```bash
SERVER_PORT=8080
```

Frontend will be accessible at `http://<SERVER_HOST>:8080`

## Support

For issues and questions:
- **PatchMon Documentation**: Check official docs
- **Docker Compose Issues**: Review logs with `docker compose logs`
- **Raspberry Pi Issues**: Check temperature, memory, and throttling status

## License

[Your License Here]
