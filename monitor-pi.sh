#!/bin/bash
# Raspberry Pi 5 Monitoring Script for PatchMon
# This script displays current system status and Docker container health

echo "========================================="
echo "  Raspberry Pi 5 - PatchMon Monitor"
echo "========================================="
echo ""

# System Status
echo "=== System Status ==="
echo "Date/Time: $(date)"
echo "Uptime: $(uptime -p)"
echo ""

# Temperature and Throttling
echo "=== Temperature & Throttling ==="
TEMP=$(vcgencmd measure_temp | cut -d'=' -f2)
THROTTLE=$(vcgencmd get_throttled)
echo "Temperature: $TEMP"
echo "Throttling Status: $THROTTLE"

if [ "$THROTTLE" != "throttled=0x0" ]; then
    echo "⚠️  WARNING: System is throttled! Check cooling."
else
    echo "✓ No throttling detected"
fi
echo ""

# CPU Usage
echo "=== CPU Usage ==="
top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print "CPU Usage: " 100 - $1"%"}'
echo ""

# Memory Usage
echo "=== Memory Usage ==="
free -h | grep -E "Mem:|Swap:"
MEMORY_PERCENT=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
echo "Memory Usage: $MEMORY_PERCENT%"

if [ $MEMORY_PERCENT -gt 85 ]; then
    echo "⚠️  WARNING: High memory usage!"
fi
echo ""

# Disk Usage
echo "=== Disk Usage ==="
df -h | grep -E "Filesystem|/$|/boot" | grep -v tmpfs
DISK_PERCENT=$(df -h | grep -E "/$" | awk '{print $5}' | sed 's/%//')

if [ $DISK_PERCENT -gt 85 ]; then
    echo "⚠️  WARNING: Disk usage is high!"
fi
echo ""

# Docker Container Status
echo "=== Docker Container Status ==="
if command -v docker &> /dev/null; then
    if docker compose ps &> /dev/null; then
        docker compose ps
        echo ""
        echo "=== Docker Resource Usage ==="
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
    else
        echo "Docker Compose not running or not in correct directory"
    fi
else
    echo "Docker not found"
fi
echo ""

# Network Status
echo "=== Network Status ==="
echo "IP Address(es): $(hostname -I | awk '{print $1}')"
echo "Gateway: $(ip route | grep default | awk '{print $3}')"
echo ""

echo "========================================="
echo "  Monitoring complete"
echo "========================================="
