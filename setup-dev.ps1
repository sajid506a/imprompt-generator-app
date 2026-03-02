#!/usr/bin/env pwsh

# AI SAAS Development Environment Setup for Windows

Write-Host @"
╔═══════════════════════════════════════════════════════╗
║   imprompt generator Development Environment Setup 🚀  ║
╚═══════════════════════════════════════════════════════╝
"@

Write-Host ""
Write-Host "📋 Checking prerequisites..."

# Check Docker
$docker = docker --version 2>$null
if ($null -eq $docker) {
    Write-Host "❌ Docker is not installed. Please install Docker Desktop first."
    Write-Host "   Download: https://www.docker.com/products/docker-desktop"
    exit 1
}
Write-Host "✅ Docker found: $docker"

# Check Docker Compose
$dockerCompose = docker-compose --version 2>$null
if ($null -eq $dockerCompose) {
    Write-Host "❌ Docker Compose is not installed."
    exit 1
}
Write-Host "✅ Docker Compose found: $dockerCompose"

# Setup environment
Write-Host ""
Write-Host "🔧 Setting up environment..."

if (-not (Test-Path ".env")) {
    Write-Host "Creating .env file from .env.example..."
    Copy-Item ".env.example" ".env"
    Write-Host "✅ .env created. Please update with your configuration."
}
else {
    Write-Host "✅ .env already exists"
}

# Build and start containers
Write-Host ""
Write-Host "🐳 Building and starting Docker containers..."
docker-compose -f docker-compose.dev.yml down 2>$null
docker-compose -f docker-compose.dev.yml build
docker-compose -f docker-compose.dev.yml up -d

# Wait for services
Write-Host ""
Write-Host "⏳ Waiting for services to be ready (30 seconds)..."
Start-Sleep -Seconds 30

# Check health
Write-Host ""
Write-Host "🏥 Checking service health..."

Try {
    $health = Invoke-WebRequest -Uri "http://localhost:3000/health" -UseBasicParsing -ErrorAction Stop
    Write-Host "✅ API Gateway is healthy"
}
Catch {
    Write-Host "⚠️  API Gateway is not responding yet, but it may still be starting..."
}

# Display information
Write-Host @"

╔═══════════════════════════════════════════════════════╗
║              Setup Complete! 🎉                       ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
│ API Gateway:     http://localhost:3000                ║
│ PostgreSQL:      localhost:5432                       ║
│ Redis:           localhost:6379                       ║
│ Ollama:          http://localhost:11434               ║
│                                                       ║
│ API Health:      http://localhost:3000/health         ║
│                                                       ║
║ Useful Commands:                                      ║
│ - View logs:     docker-compose -f docker-compose.dev.yml logs -f api
│ - Stop services: docker-compose -f docker-compose.dev.yml down
│ - Rebuild:       docker-compose -f docker-compose.dev.yml build
│                                                       ║
╚═══════════════════════════════════════════════════════╝

"@
