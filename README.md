# imprompt generator - Complete SaaS Platform

A production-ready full-stack SaaS platform with:
- **Angular UI** - Modern, responsive web interface
- **Express.js API Gateway** - Secure REST API with JWT authentication
- **Worker Agents** - Background job processing with Redis queues
- **RAG (Retrieval Augmented Generation)** - PDF embedding and semantic search
- **Ollama LLM Integration** - Local LLM inference support
- **PostgreSQL Database** - Persistent data storage with migrations
- **Redis Cache** - Session management and job queuing
- **Docker & Kubernetes** - Container orchestration ready
- **JWT Authentication** - Secure token-based auth
- **Rate Limiting** - DDoS protection and API quotas

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start - Local Development](#quick-start---local-development)
3. [Production Deployment](#production-deployment)
4. [Project Structure](#project-structure)
5. [API Endpoints](#api-endpoints)
6. [Configuration](#configuration)
7. [Database](#database)
8. [Security](#security)
9. [Troubleshooting](#troubleshooting)
10. [Contributing](#contributing)

---

## Prerequisites

### Required
- **Docker** 20.10+ ([Install](https://docs.docker.com/get-docker/))
- **Docker Compose** 2.0+ ([Install](https://docs.docker.com/compose/install/))
- **Git** ([Install](https://git-scm.com/))

### For Local Development (without Docker)
- **Node.js** 18+ ([Install](https://nodejs.org/))
- **PostgreSQL** 15+ ([Install](https://www.postgresql.org/download/))
- **Redis** 7+ ([Install](https://redis.io/download))

---

## Quick Start - Local Development

### Option 1: Using Docker Compose (Recommended)

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/imprompt-generator-app-v1.git
   cd imprompt-generator-app-v1
   ```

2. **Copy environment template**
   ```bash
   cp .env.example .env
   ```

3. **Edit environment variables** (optional - defaults work for dev)
   ```bash
   # Edit .env with your configuration
   nano .env
   ```

4. **Run setup script** (Linux/Mac)
   ```bash
   chmod +x setup-dev.sh
   ./setup-dev.sh
   ```

   Or manually start services:
   ```bash
   docker-compose -f docker-compose.dev.yml up -d
   ```

5. **Verify setup**
   ```bash
   # Check API health
   curl http://localhost:3000/health
   
   # Expected response:
   # {"status":"ok","environment":"development","timestamp":"2024-03-02T10:00:00.000Z"}
   ```

### Option 2: Local Installation (without Docker)

1. **Install dependencies**
   ```bash
   # API Gateway
   cd apps/api-gateway
   npm install
   
   # Worker Agents
   cd ../appsworker-agents
   npm install
   
   # Web UI
   cd ../web-angular
   npm install
   ```

2. **Setup database**
   ```bash
   # Create database
   psql -U postgres -c "CREATE DATABASE aisaas;"
   psql -U postgres -d aisaas -f database/schema.sql
   ```

3. **Create .env file**
   ```bash
   cp .env.example .env
   
   # Edit with your local configuration:
   DB_HOST=localhost
   DB_USER=postgres
   DB_PASSWORD=yourpassword
   REDIS_URL=redis://localhost:6379
   # etc.
   ```

4. **Start services** (in separate terminals)
   ```bash
   # Terminal 1: API Gateway
   cd apps/api-gateway
   npm run dev
   
   # Terminal 2: Worker
   cd apps/appsworker-agents
   npm start
   
   # Terminal 3: Web UI
   cd apps/web-angular
   ng serve --host 0.0.0.0
   ```

### Access the Application

- **API**: http://localhost:3000
- **Web UI**: http://localhost:4200
- **API Health**: http://localhost:3000/health
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379
- **Ollama**: http://localhost:11434

### Development Workflows

**View API logs:**
```bash
docker-compose -f docker-compose.dev.yml logs -f api
```

**Stop all services:**
```bash
docker-compose -f docker-compose.dev.yml down
```

**Reset database:**
```bash
docker-compose -f docker-compose.dev.yml down -v  # removes volumes
docker-compose -f docker-compose.dev.yml up -d
```

**Rebuild containers after code changes:**
```bash
docker-compose -f docker-compose.dev.yml build
docker-compose -f docker-compose.dev.yml up -d
```

---

## Production Deployment

### Prerequisites for Production

- **SSL/TLS Certificate** (required for HTTPS)
- **Domain Name** (for your API endpoints)
- **Cloud Infrastructure** (AWS, GCP, Azure, or dedicated server)
- **Security Group/Firewall** configured
- **Database Backups** strategy (automated daily minimum)
- **Monitoring & Alerting** (optional but recommended)

### Option 1: Docker Compose Production Deployment

1. **Prepare your server**
   ```bash
   # Create application directory
   mkdir -p /opt/imprompt-generator-app
   cd /opt/imprompt-generator-app
   
   # Clone repository
   git clone https://github.com/yourusername/imprompt-generator-app-v1.git .
   ```

2. **Configure production environment**
   ```bash
   # Create production .env file
   cp .env.example .env
   
   # Edit with your production values
   nano .env
   ```

   **Critical production values to set:**
   ```bash
   NODE_ENV=production
   JWT_SECRET=<strong-random-secret>  # Use: openssl rand -hex 32
   DB_PASSWORD=<strong-password>      # Use: openssl rand -base64 32
   CORS_ORIGIN=https://yourdomain.com
   REDIS_PASSWORD=<redis-password>
   ```

3. **Generate secure secrets**
   ```bash
   # Generate JWT secret
   openssl rand -hex 32
   
   # Generate database password
   openssl rand -base64 32
   ```

4. **Run production setup**
   ```bash
   chmod +x setup-prod.sh
   ./setup-prod.sh
   ```

5. **Verify deployment**
   ```bash
   # Check all services
   docker-compose -f docker-compose.prod.yml ps
   
   # Check API health
   curl https://yourdomain.com/health
   
   # View logs
   docker-compose -f docker-compose.prod.yml logs -f api
   ```

### Option 2: Kubernetes Deployment

**Deploy using provided manifests:**

```bash
# Create namespace
kubectl create namespace imprompt-generator-app

# Create secrets
kubectl create secret generic imprompt-generator-app-secrets \
  --from-literal=jwt-secret=$(openssl rand -hex 32) \
  --from-literal=db-password=$(openssl rand -base64 32) \
  -n imprompt-generator-app

# Apply manifests
kubectl apply -f infrastructure/k8s/ -n imprompt-generator-app

# Verify deployment
kubectl get pods -n imprompt-generator-app
kubectl get svc -n imprompt-generator-app
```

### Option 3: Managed Services (AWS, GCP, Azure)

Refer to cloud-specific guides:
- [AWS ECS/Fargate Deployment Guide](./docs/deployment/aws.md)
- [GCP Cloud Run Deployment Guide](./docs/deployment/gcp.md)
- [Azure Container Instances Guide](./docs/deployment/azure.md)

### Production Monitoring

**Health Checks:**
```bash
# API health endpoint
GET /health

# Database health
docker-compose -f docker-compose.prod.yml exec postgres pg_isready

# Redis health
docker-compose -f docker-compose.prod.yml exec redis redis-cli ping
```

**View Logs:**
```bash
# All services
docker-compose -f docker-compose.prod.yml logs -f

# Specific service
docker-compose -f docker-compose.prod.yml logs -f api
docker-compose -f docker-compose.prod.yml logs -f worker
```

**Database Backup:**
```bash
# Manual backup
docker-compose -f docker-compose.prod.yml exec postgres \
  pg_dump -U ai aisaas > backup-$(date +%Y%m%d).sql

# Automated: Setup cron job
# 0 2 * * * docker-compose -f /opt/imprompt-generator-app/docker-compose.prod.yml exec postgres pg_dump -U ai aisaas > /backups/aisaas-$(date +\%Y\%m\%d).sql
```

---

## Project Structure

```
imprompt-generator-app-v1/
├── apps/
│   ├── api-gateway/              # Express.js API server
│   │   ├── server.js             # Main application
│   │   ├── Dockerfile            # Container image definition
│   │   └── package.json          # Dependencies
│   ├── appsworker-agents/        # Background job worker
│   │   ├── worker.js             # Worker service
│   │   ├── Dockerfile            # Container image
│   │   └── package.json          # Dependencies
│   └── web-angular/              # Angular web UI
│       ├── src/
│       │   ├── app/              # Application components
│       │   │   ├── auth/         # Authentication module
│       │   │   ├── chat/         # Chat component
│       │   │   └── visual-builder/ # Builder interface
│       │   └── main.ts           # Entry point
│       └── angular.json          # Angular config
├── packages/
│   ├── auth/
│   │   └── jwt.middleware.js     # JWT validation middleware
│   └── rag/
│       └── rag.service.js        # RAG document processing
├── database/
│   └── schema.sql                # Database schema
├── infrastructure/
│   └── k8s/                      # Kubernetes manifests
│       ├── api-deployment.yaml   # API deployment config
│       └── service.yaml          # Kubernetes service
├── docker-compose.yml            # (Legacy - use .dev or .prod)
├── docker-compose.dev.yml        # Development environment
├── docker-compose.prod.yml       # Production environment
├── .env.example                  # Environment template
├── setup-dev.sh                  # Development setup script
├── setup-prod.sh                 # Production setup script
└── README.md                     # This file
```

---

## API Endpoints

### Authentication

**Login**
```bash
POST /login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}

Response:
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": "7d",
  "message": "Login successful"
}
```

### RAG (Retrieval Augmented Generation)

**Upload PDF**
```bash
POST /upload
Content-Type: multipart/form-data
Authorization: Bearer <token>

Form Data:
- file: <pdf_file>

Response:
{
  "message": "PDF uploaded successfully for RAG",
  "filename": "550e8400-e29b-41d4-a716-446655440000.pdf",
  "originalName": "document.pdf",
  "size": 1024000,
  "path": "./uploads/550e8400-e29b-41d4-a716-446655440000.pdf"
}
```

**Stream Responses**
```bash
POST /stream
Authorization: Bearer <token>

Response (Server-Sent Events):
data: {"token":"token-0","index":0}
data: {"token":"token-1","index":1}
...
data: {"complete":true}
```

### Health Check

**Health Status**
```bash
GET /health

Response:
{
  "status": "ok",
  "environment": "development",
  "timestamp": "2024-03-02T10:00:00.000Z"
}
```

---

## Configuration

### Environment Variables

Create a `.env` file in the project root. See `.env.example` for all available options.

**Key Variables:**

| Variable | Description | Default | Production |
|----------|-------------|---------|------------|
| `NODE_ENV` | Application environment | development | production |
| `PORT` | API server port | 3000 | 3000 |
| `JWT_SECRET` | JWT signing secret | change-me | **REQUIRED** |
| `DB_HOST` | Database host | postgres | prod-db.example.com |
| `DB_PASSWORD` | Database password | ai | **REQUIRED** |
| `CORS_ORIGIN` | Allowed CORS origins | http://localhost:4200 | https://yourdomain.com |
| `REDIS_URL` | Redis connection URL | redis://redis:6379 | redis://redis:6379 |
| `OLLAMA_URL` | Ollama service URL | http://ollama:11434 | http://ollama:11434 |
| `RATE_LIMIT_MAX_REQUESTS` | Requests per time window | 100 | 100 |
| `LOG_LEVEL` | Logging level | debug | info |

### File Upload Configuration

```bash
UPLOAD_DIR=./uploads                    # Upload directory
MAX_FILE_SIZE=52428800                 # Max 50MB
ALLOWED_MIME_TYPES=application/pdf,text/plain
```

---

## Database

### Schema

The database includes three main tables:

```sql
-- Workspaces (multi-tenancy)
CREATE TABLE workspaces (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Users
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  workspace_id INT REFERENCES workspaces(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Usage Logs (for billing/analytics)
CREATE TABLE usage_logs (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id),
  tokens INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Database Management

**Connect to database:**
```bash
# Using Docker
docker-compose -f docker-compose.dev.yml exec postgres \
  psql -U ai -d aisaas

# Local PostgreSQL
psql -U ai -d aisaas -h localhost
```

**Backup database:**
```bash
pg_dump -U ai -d aisaas > backup.sql
```

**Restore database:**
```bash
psql -U ai -d aisaas < backup.sql
```

---

## Security

### Production Security Checklist

- [ ] Change all default credentials (JWT secret, DB password, Redis password)
- [ ] Enable HTTPS/TLS on API endpoints
- [ ] Configure firewall rules (restrict database/Redis access)
- [ ] Enable rate limiting on all endpoints
- [ ] Set up WAF (Web Application Firewall)
- [ ] Configure CORS properly for your domain only
- [ ] Enable database encryption at rest
- [ ] Set up automated backups with point-in-time recovery
- [ ] Configure monitoring and alerting
- [ ] Set up log aggregation (ELK, Datadog, etc.)
- [ ] Regular security updates and patches
- [ ] SQL injection protection (parameterized queries - already implemented)
- [ ] CSRF protection on state-changing operations
- [ ] Input validation on all endpoints (already implemented)
- [ ] DDoS protection (set up rate limiting, WAF rules)

### JWT Secret Generation

```bash
# Generate secure JWT secret
openssl rand -hex 32

# Example output:
# a8f3c9e2b1d4f6a9e2c5b8d1f4e7a0c3d6f9a2b5e8c1d4f7a0b3c6d9e2f5
```

### File Upload Security

- ✅ MIME type validation
- ✅ File size limits (50MB max)
- ✅ Unique file naming (UUID)
- ✅ Protected upload directory

---

## Troubleshooting

### Docker Issues

**Containers not starting:**
```bash
# Check logs
docker-compose -f docker-compose.dev.yml logs

# Rebuild containers
docker-compose -f docker-compose.dev.yml build --no-cache
docker-compose -f docker-compose.dev.yml up -d
```

**Port already in use:**
```bash
# Find process using port 3000
lsof -i :3000

# Kill process
kill -9 <PID>

# Or change port in .env
```

### Database Issues

**Database connection refused:**
```bash
# Check if PostgreSQL is running
docker-compose -f docker-compose.dev.yml exec postgres pg_isready

# Check database logs
docker-compose -f docker-compose.dev.yml logs postgres
```

**Database locked:**
```bash
# Connect and terminate conflicting connections
docker-compose -f docker-compose.dev.yml exec postgres psql -U ai -d aisaas
SELECT * FROM pg_stat_activity WHERE datname = 'aisaas';
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'aisaas' AND pid != pg_backend_pid();
```

### API Issues

**JWT token invalid:**
- Verify JWT secret matches between API and .env
- Check token expiration: `jwt decode <token>`
- Ensure Authorization header format: `Authorization: Bearer <token>`

**CORS errors:**
- Check CORS_ORIGIN in .env matches your frontend domain
- Multiple origins separated by comma: `http://localhost:4200,https://yourdomain.com`

### Redis Issues

**Redis connection error:**
```bash
# Check Redis status
docker-compose -f docker-compose.dev.yml exec redis redis-cli ping

# View Redis logs
docker-compose -f docker-compose.dev.yml logs redis
```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Email: support@aisaas.com
- Documentation: https://docs.aisaas.com

---

**Last Updated:** March 2, 2026
**Version:** 1.0.0-production"# imprompt-generator-app" 
