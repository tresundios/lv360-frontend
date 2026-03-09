.PHONY: up down logs build test lint format dev-full clean

# Local development (frontend only)
up:
	docker compose -f docker-compose.local.yml --env-file .env.local up -d

down:
	docker compose -f docker-compose.local.yml down

logs:
	docker compose -f docker-compose.local.yml logs -f

build:
	docker compose -f docker-compose.local.yml build

clean:
	docker compose -f docker-compose.local.yml down -v
	docker system prune -f

# Frontend specific commands
test:
	cd frontend && npm test

lint:
	cd frontend && npm run lint

format:
	cd frontend && npm run format

install:
	cd frontend && npm install

dev:
	cd frontend && npm run dev

# Full stack development (requires backend running)
dev-full:
	@echo "Make sure backend is running first"
	docker compose -f docker-compose.local.yml --env-file .env.local up -d

# Production deployment
deploy-dev:
	docker compose -f docker-compose.dev.yml --env-file .env.dev pull
	docker compose -f docker-compose.dev.yml --env-file .env.dev up -d

# Health check
health:
	curl -f http://localhost:3080/ || echo "Frontend not ready"

# Shell access
shell:
	docker compose -f docker-compose.local.yml exec frontend sh
