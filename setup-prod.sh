#!/bin/bash

set -e

echo "╔═══════════════════════════════════════════════════════╗"
echo "║   imprompt generator Production Environment Setup 🚀   ║"
echo "╚═══════════════════════════════════════════════════════╝"

# Check prerequisites
echo ""
echo "📋 Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "✅ Docker and Docker Compose found"

# Check for .env file
echo ""
echo "🔍 Checking configuration..."

if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    echo "Please create a .env file with production configuration."
    echo "You can use .env.example as a template."
    exit 1
fi

echo "✅ .env file found"

# Verify critical environment variables
REQUIRED_VARS=("JWT_SECRET" "DB_PASSWORD" "CORS_ORIGIN" "DB_USER" "DB_NAME")
for var in "${REQUIRED_VARS[@]}"; do
    if ! grep -q "^$var=" .env; then
        echo "❌ Required variable $var not found in .env"
        exit 1
    fi
done
echo "✅ All required environment variables are set"

# Build and start containers
echo ""
echo "🐳 Building and starting Docker containers..."
docker-compose -f docker-compose.prod.yml down || true
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d

# Wait for services
echo ""
echo "⏳ Waiting for services to be ready (60 seconds)..."
sleep 60

# Run database migrations
echo ""
echo "🗄️  Initializing database..."
docker-compose -f docker-compose.prod.yml exec -T postgres psql \
  -U $(grep "^DB_USER=" .env | cut -d= -f2) \
  -d $(grep "^DB_NAME=" .env | cut -d= -f2) \
  -f /docker-entrypoint-initdb.d/01-schema.sql 2>/dev/null || true

# Pull Ollama model
echo ""
echo "📥 Pulling Ollama model (this may take a few minutes)..."
docker-compose -f docker-compose.prod.yml exec -T ollama ollama pull llama3 || true

# Check service health
echo ""
echo "🏥 Checking service health..."

for i in {1..10}; do
    if curl -s -f http://localhost:3000/health > /dev/null 2>&1; then
        echo "✅ API Gateway is healthy"
        break
    fi
    echo "⏳ Waiting for API Gateway... ($i/10)"
    sleep 6
done

# Display information
echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║         Production Setup Complete! 🎉                 ║"
echo "╠═══════════════════════════════════════════════════════╣"
echo "║                                                       ║"
echo "│ API Gateway:     http://localhost:3000                ║"
echo "│ PostgreSQL:      localhost:5432                       ║"
echo "│ Redis:           localhost:6379                       ║"
echo "│ Ollama:          http://localhost:11434               ║"
echo "│                                                       ║"
echo "│ API Health:      http://localhost:3000/health         ║"
echo "│                                                       ║"
echo "║ Important Commands:                                   ║"
echo "│ - View logs:     docker-compose -f docker-compose.prod.yml logs -f"
echo "│ - Stop services: docker-compose -f docker-compose.prod.yml down"
echo "│ - Restart:       docker-compose -f docker-compose.prod.yml restart"
echo "│ - DB Shell:      docker-compose -f docker-compose.prod.yml exec postgres psql -U <user> -d <db>"
echo "│                                                       ║"
echo "║ ⚠️  SECURITY REMINDERS:                                ║"
echo "│ 1. Change JWT_SECRET in .env to a strong value       ║"
echo "│ 2. Change database password to a strong value        ║"
echo "│ 3. Enable SSL/TLS on the API endpoint                ║"
echo "│ 4. Configure proper firewall rules                   ║"
echo "│ 5. Set up monitoring and alerting                    ║"
echo "│ 6. Configure automated backups                       ║"
echo "│                                                       ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
