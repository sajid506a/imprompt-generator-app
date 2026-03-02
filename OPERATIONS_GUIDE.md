# Operations Guide

This guide provides instructions for operating the imprompt generator platform in production.

## Table of Contents

1. [Starting & Stopping Services](#starting--stopping-services)
2. [Monitoring](#monitoring)
3. [Scaling](#scaling)
4. [Database Management](#database-management)
5. [Troubleshooting](#troubleshooting)
6. [Emergency Procedures](#emergency-procedures)

---

## Starting & Stopping Services

### Start All Services

```bash
docker-compose -f docker-compose.prod.yml up -d
```

Verify startup:
```bash
docker-compose -f docker-compose.prod.yml ps
```

### Stop All Services

```bash
docker-compose -f docker-compose.prod.yml down
```

### Restart Services

**Restart all:**
```bash
docker-compose -f docker-compose.prod.yml restart
```

**Restart specific service:**
```bash
docker-compose -f docker-compose.prod.yml restart api
docker-compose -f docker-compose.prod.yml restart worker
docker-compose -f docker-compose.prod.yml restart postgres
```

### View Logs

**All services:**
```bash
docker-compose -f docker-compose.prod.yml logs -f
```

**Specific service (last 100 lines):**
```bash
docker-compose -f docker-compose.prod.yml logs --tail=100 api
docker-compose -f docker-compose.prod.yml logs --tail=100 worker
docker-compose -f docker-compose.prod.yml logs --tail=100 postgres
```

**Search logs for errors:**
```bash
docker-compose -f docker-compose.prod.yml logs api | grep -i error
```

---

## Monitoring

### Health Checks

**API Gateway:**
```bash
curl -s http://localhost:3000/health | jq .
```

Expected response:
```json
{
  "status": "ok",
  "environment": "production",
  "timestamp": "2024-03-02T10:00:00.000Z"
}
```

**PostgreSQL:**
```bash
docker-compose -f docker-compose.prod.yml exec postgres pg_isready
```

Expected output: `accepting connections`

**Redis:**
```bash
docker-compose -f docker-compose.prod.yml exec redis redis-cli ping
```

Expected output: `PONG`

### Check Service Status

```bash
docker-compose -f docker-compose.prod.yml ps
```

### Resource Usage

```bash
docker stats --no-stream
```

Monitor:
- Memory usage (should be < 80% of available)
- CPU usage (should be < 70% sustained)
- Disk I/O

### Database Monitoring

```bash
# Connect to database
docker-compose -f docker-compose.prod.yml exec postgres psql -U ai -d aisaas

# Useful queries:
# Connection count
SELECT datname, count(datname) FROM pg_stat_activity GROUP BY datname;

# Long running queries
SELECT now() - query_start as duration, query FROM pg_stat_activity 
WHERE state = 'active' ORDER BY duration DESC;

# Unused indexes
SELECT schemaname, tablename, indexname 
FROM pg_indexes WHERE idx_scan = 0 AND indexname NOT LIKE 'pg_toast%';

# Table sizes
SELECT schemaname, tablename, 
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) 
FROM pg_tables WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

---

## Scaling

### Horizontal Scaling (Multiple Workers)

Create additional worker instances:

```bash
# In docker-compose.prod.yml, add more worker services:
worker-2:
  build:
    context: ./apps/appsworker-agents
    dockerfile: Dockerfile
  container_name: imprompt-generator-app-worker-2
  restart: always
  environment:
    NODE_ENV: production
    REDIS_URL: redis://redis:6379
    WORKER_ID: worker-2
  depends_on:
    redis:
      condition: service_healthy
  networks:
    - imprompt-generator-app-network

worker-3:
  build:
    context: ./apps/appsworker-agents
    dockerfile: Dockerfile
  container_name: imprompt-generator-app-worker-3
  restart: always
  environment:
    NODE_ENV: production
    REDIS_URL: redis://redis:6379
    WORKER_ID: worker-3
  depends_on:
    redis:
      condition: service_healthy
  networks:
    - imprompt-generator-app-network

# Then restart
docker-compose -f docker-compose.prod.yml up -d
```

### Vertical Scaling (Increase Resource Limits)

Update resource limits in docker-compose.prod.yml:

```yaml
services:
  api:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

### Load Balancing

For production, use a reverse proxy like nginx or HAProxy:

```nginx
# nginx.conf example
upstream api_backend {
  server api:3000;
  # Add more servers for load balancing
}

server {
  listen 443 ssl http2;
  server_name yourdomain.com;

  ssl_certificate /etc/nginx/certs/cert.pem;
  ssl_certificate_key /etc/nginx/certs/key.pem;

  location / {
    proxy_pass http://api_backend;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
```

---

## Database Management

### Backup

**Manual backup:**
```bash
docker-compose -f docker-compose.prod.yml exec -T postgres \
  pg_dump -U ai -d aisaas > backup-$(date +%Y%m%d-%H%M%S).sql
```

**Verify backup:**
```bash
head -20 backup-*.sql
ls -lh backup-*.sql
```

**Upload backup to S3:**
```bash
aws s3 cp backup-*.sql s3://your-bucket/backups/
```

### Restore

```bash
# From backup file
docker-compose -f docker-compose.prod.yml exec -T postgres \
  psql -U ai -d aisaas < backup-20240302-120000.sql
```

### Scheduled Backups (Cron)

Create backup script:

```bash
#!/bin/bash
# /usr/local/bin/backup-db.sh

BACKUP_DIR="/backups"
DB_NAME="aisaas"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/aisaas-$TIMESTAMP.sql"

# Create backup
docker-compose -f /opt/imprompt-generator-app/docker-compose.prod.yml exec -T postgres \
  pg_dump -U ai -d $DB_NAME > $BACKUP_FILE

# Compress
gzip $BACKUP_FILE

# Upload to S3
aws s3 cp "$BACKUP_FILE.gz" "s3://your-bucket/backups/"

# Keep only last 30 days locally
find $BACKUP_DIR -name "*.sql.gz" -mtime +30 -delete

echo "Backup completed: $BACKUP_FILE.gz"
```

Add to crontab:
```bash
# Run daily at 2 AM
0 2 * * * /usr/local/bin/backup-db.sh >> /var/log/db-backup.log 2>&1
```

### Database Maintenance

**Run VACUUM (cleanup dead tuples):**
```bash
docker-compose -f docker-compose.prod.yml exec postgres \
  psql -U ai -d aisaas -c "VACUUM ANALYZE;"
```

**Reindex tables:**
```bash
docker-compose -f docker-compose.prod.yml exec postgres \
  psql -U ai -d aisaas -c "REINDEX DATABASE aisaas;"
```

---

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose -f docker-compose.prod.yml logs api

# Rebuild container
docker-compose -f docker-compose.prod.yml build --no-cache api
docker-compose -f docker-compose.prod.yml up -d api
```

### High Memory Usage

```bash
# Check which containers are using memory
docker stats

# If API is using too much:
docker-compose -f docker-compose.prod.yml restart api

# Check for memory leaks in logs
docker-compose -f docker-compose.prod.yml logs api | grep -i "memory"
```

### Database Connection Errors

```bash
# Check PostgreSQL is running
docker-compose -f docker-compose.prod.yml exec postgres pg_isready

# Check connection limit
docker-compose -f docker-compose.prod.yml exec postgres psql -U ai -d aisaas \
  -c "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;"

# Increase max_connections in docker-compose.prod.yml:
# environment:
#   - POSTGRES_INIT_ARGS=-c max_connections=200
```

### Redis Connection Errors

```bash
# Test Redis
docker-compose -f docker-compose.prod.yml exec redis redis-cli ping

# Check memory
docker-compose -f docker-compose.prod.yml exec redis redis-cli info memory

# Clear cache (be careful in production)
docker-compose -f docker-compose.prod.yml exec redis redis-cli FLUSHDB
```

### Slow API Response

```bash
# Check API logs for slow requests
docker-compose -f docker-compose.prod.yml logs api | grep slow

# Check CPU/memory
docker stats

# Check database query performance
docker-compose -f docker-compose.prod.yml exec postgres psql -U ai -d aisaas \
  -c "SELECT query, calls, mean_time FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"
```

---

## Emergency Procedures

### Complete Service Failure

```bash
# 1. Stop all services
docker-compose -f docker-compose.prod.yml down

# 2. Check system resources
free -h
df -h

# 3. Rebuild and restart
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d

# 4. Verify health
sleep 30
docker-compose -f docker-compose.prod.yml ps
curl http://localhost:3000/health
```

### Database Corruption

```bash
# 1. Stop services
docker-compose -f docker-compose.prod.yml down

# 2. Restore from backup
docker-compose -f docker-compose.prod.yml up -d postgres
sleep 10

docker-compose -f docker-compose.prod.yml exec -T postgres \
  psql -U ai -d aisaas < /backups/backup-latest.sql

# 3. Run integrity check
docker-compose -f docker-compose.prod.yml exec postgres \
  psql -U ai -d aisaas -c "SELECT pg_database.datname, 
  pg_size_pretty(pg_database_size(pg_database.datname)) 
  FROM pg_database;"

# 4. Restart all services
docker-compose -f docker-compose.prod.yml up -d
```

### Disk Space Issues

```bash
# Check disk usage
df -h

# Find large files
find / -type f -size +100M -exec ls -lh {} \; 2>/dev/null

# Clean up Docker images/containers
docker system prune -a

# Clean up logs (be careful)
sudo find /var/lib/docker/containers -name "*.log" -delete

# Clear old backups
rm -f /backups/*-$(date -d '30 days ago' +%Y%m%d)*.sql.gz
```

### Performance Degradation

```bash
# 1. Check running processes
docker stats

# 2. Check database for slow queries
docker-compose -f docker-compose.prod.yml exec postgres \
  psql -U ai -d aisaas -c "\dt+" | head -20

# 3. Check worker queue
docker-compose -f docker-compose.prod.yml exec redis \
  redis-cli LLEN job-queue

# 4. Scale up if needed
# Edit docker-compose.prod.yml and add more worker instances
docker-compose -f docker-compose.prod.yml up -d --scale worker=3
```

---

**Last Updated:** March 2, 2026
