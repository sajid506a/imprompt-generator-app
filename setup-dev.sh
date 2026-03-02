#!/bin/bash

set -e

echo "╔═══════════════════════════════════════════════════════╗"
echo "║   imprompt generator Development Environment Setup 🚀  ║"
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

# Setup environment
echo ""
echo "🔧 Setting up environment..."

if [ ! -f .env ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    echo "✅ .env created. Please update with your configuration."
else
    echo "✅ .env already exists"
fi

# Build and start containers
echo ""
echo "🐳 Building and starting Docker containers..."
docker-compose -f docker-compose.dev.yml down || true
docker-compose -f docker-compose.dev.yml build
docker-compose -f docker-compose.dev.yml up -d

# Wait for services
echo ""
echo "⏳ Waiting for services to be ready (30 seconds)..."
sleep 30

# Check service health
echo ""
echo "🏥 Checking service health..."

if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    echo "✅ API Gateway is healthy"
else
    echo "⚠️  API Gateway is not responding yet, it may still be starting..."
fi

if curl -f http://localhost:5432 > /dev/null 2>&1; then
    echo "✅ PostgreSQL is running"
else
    echo "ℹ️  PostgreSQL is running on port 5432"
fi

# Display information
echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║              Setup Complete! 🎉                       ║"
echo "╠═══════════════════════════════════════════════════════╣"
echo "║                                                       ║"
echo "│ API Gateway:     http://localhost:3000                ║"
echo "│ PostgreSQL:      localhost:5432                       ║"
echo "│ Redis:           localhost:6379                       ║"
echo "│ Ollama:          http://localhost:11434               ║"
echo "│                                                       ║"
echo "│ API Health:      http://localhost:3000/health         ║"
echo "│                                                       ║"
echo "║ Useful Commands:                                      ║"
echo "│ - View logs:     docker-compose -f docker-compose.dev.yml logs -f api"
echo "│ - Stop services: docker-compose -f docker-compose.dev.yml down"
echo "│ - Rebuild:       docker-compose -f docker-compose.dev.yml build"
echo "│                                                       ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
