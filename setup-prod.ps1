#!/usr/bin/env pwsh

# AI SAAS Production Environment Setup for Windows

Write-Host @"
╔═══════════════════════════════════════════════════════╗
║   imprompt generator Production Environment Setup 🚀   ║
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

# Check for .env file
Write-Host ""
Write-Host "🔍 Checking configuration..."

if (-not (Test-Path ".env")) {
    Write-Host "❌ .env file not found!"
    Write-Host "Please create a .env file with production configuration."
    Write-Host "You can use .env.example as a template."
    exit 1
}
Write-Host "✅ .env file found"

# Build and start containers
Write-Host ""
Write-Host "🐳 Building and starting Docker containers..."
docker-compose -f docker-compose.prod.yml down 2>$null
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d

# Wait for services
Write-Host ""
Write-Host "⏳ Waiting for services to be ready (60 seconds)..."
Start-Sleep -Seconds 60

# Pull Ollama model
Write-Host ""
Write-Host "📥 Pulling Ollama model (this may take a few minutes)..."
docker-compose -f docker-compose.prod.yml exec -T ollama ollama pull llama3 2>$null

# Check health
Write-Host ""
Write-Host "🏥 Checking service health..."

$retries = 0
$maxRetries = 10
while ($retries -lt $maxRetries) {
    Try {
        $health = Invoke-WebRequest -Uri "http://localhost:3000/health" -UseBasicParsing -ErrorAction Stop
        Write-Host "✅ API Gateway is healthy"
        break
    }
    Catch {
        $retries++
        Write-Host "⏳ Waiting for API Gateway... ($retries/$maxRetries)"
        Start-Sleep -Seconds 6
    }
}

# Display information
Write-Host @"

╔═══════════════════════════════════════════════════════╗
║         Production Setup Complete! 🎉                 ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
│ API Gateway:     http://localhost:3000                ║
│ PostgreSQL:      localhost:5432                       ║
│ Redis:           localhost:6379                       ║
│ Ollama:          http://localhost:11434               ║
│                                                       ║
│ API Health:      http://localhost:3000/health         ║
│                                                       ║
║ Important Commands:                                   ║
│ - View logs:     docker-compose -f docker-compose.prod.yml logs -f
│ - Stop services: docker-compose -f docker-compose.prod.yml down
│ - Restart:       docker-compose -f docker-compose.prod.yml restart
│                                                       ║
║ ⚠️  SECURITY REMINDERS:                                ║
│ 1. Change JWT_SECRET in .env to a strong value       ║
│ 2. Change database password to a strong value        ║
│ 3. Enable SSL/TLS on the API endpoint                ║
│ 4. Configure proper firewall rules                   ║
│ 5. Set up monitoring and alerting                    ║
│ 6. Configure automated backups                       ║
│                                                       ║
╚═══════════════════════════════════════════════════════╝

"@
