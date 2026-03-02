.PHONY: help dev-up dev-down dev-logs prod-up prod-down prod-logs build db-backup db-restore health clean

help: ## Show this help message
	@echo "imprompt generator - Management Commands"
	@echo "============================="
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Development
dev-up: ## Start development environment
	docker-compose -f docker-compose.dev.yml up -d
	@echo "✅ Development environment started"
	@echo "API: http://localhost:3000"

dev-down: ## Stop development environment
	docker-compose -f docker-compose.dev.yml down
	@echo "✅ Development environment stopped"

dev-logs: ## View development logs
	docker-compose -f docker-compose.dev.yml logs -f

dev-build: ## Build development containers
	docker-compose -f docker-compose.dev.yml build

dev-restart: ## Restart development environment
	docker-compose -f docker-compose.dev.yml restart
	@echo "✅ Development environment restarted"

# Production
prod-up: ## Start production environment
	docker-compose -f docker-compose.prod.yml up -d
	@echo "✅ Production environment started"
	@sleep 30
	@docker-compose -f docker-compose.prod.yml exec -T ollama ollama pull llama3 || true
	@echo "API: http://localhost:3000"

prod-down: ## Stop production environment
	docker-compose -f docker-compose.prod.yml down
	@echo "✅ Production environment stopped"

prod-logs: ## View production logs
	docker-compose -f docker-compose.prod.yml logs -f

prod-build: ## Build production containers
	docker-compose -f docker-compose.prod.yml build --no-cache

prod-restart: ## Restart production environment
	docker-compose -f docker-compose.prod.yml restart
	@echo "✅ Production environment restarted"

# API
health: ## Check API health status
	@curl -s http://localhost:3000/health | jq . || echo "API not responding"

api-logs: ## View API logs
	docker-compose -f docker-compose.dev.yml logs -f api

api-shell: ## Access API container shell
	docker-compose -f docker-compose.dev.yml exec api sh

# Database
db-shell: ## Access PostgreSQL shell
	docker-compose -f docker-compose.dev.yml exec postgres psql -U ai -d aisaas

db-backup: ## Backup database
	docker-compose -f docker-compose.dev.yml exec -T postgres pg_dump -U ai aisaas > backup-$$(date +%Y%m%d-%H%M%S).sql
	@echo "✅ Database backup created"

db-restore: ## Restore database from backup file (use: make db-restore FILE=backup.sql)
	docker-compose -f docker-compose.dev.yml exec -T postgres psql -U ai -d aisaas < $(FILE)
	@echo "✅ Database restored from $(FILE)"

db-reset: ## Reset database (removes volumes)
	docker-compose -f docker-compose.dev.yml down -v
	docker-compose -f docker-compose.dev.yml up -d postgres redis
	@echo "✅ Database reset"

# Redis
redis-cli: ## Access Redis CLI
	docker-compose -f docker-compose.dev.yml exec redis redis-cli

# General
clean: ## Remove all containers and volumes
	docker-compose -f docker-compose.dev.yml down -v
	docker-compose -f docker-compose.prod.yml down -v
	rm -rf uploads/*
	@echo "✅ Cleanup complete"

status: ## Show status of all services
	docker-compose -f docker-compose.dev.yml ps

install-deps: ## Install npm dependencies for all services
	cd apps/api-gateway && npm install
	cd ../../apps/appsworker-agents && npm install
	@echo "✅ Dependencies installed"

lint: ## Lint code
	@echo "Running linters..."
	-docker-compose -f docker-compose.dev.yml exec api npm run lint

test: ## Run tests
	@echo "Running tests..."
	-docker-compose -f docker-compose.dev.yml exec api npm test

.DEFAULT_GOAL := help
