# LV360 Frontend

React + Vite + Tailwind + shadcn/ui frontend application for LamViec360.

## Local Development Setup

### Prerequisites
- Docker and Docker Compose
- Node.js 20+ (for local development without Docker)
- Git

### Quick Start

1. **Clone and setup:**
```bash
git clone https://github.com/tresundios/lv360-frontend.git
cd lv360-frontend
cp .env.local.example .env.local
```

2. **Start with Docker:**
```bash
make up
```

3. **Access the application:**
- Frontend: http://localhost:3080
- API: http://localhost:8000 (requires backend running)

### Development Commands

```bash
# Start frontend only
make up

# View logs
make logs

# Stop services
make down

# Run tests
make test

# Run linting
make lint

# Format code
make format

# Install dependencies
make install

# Development server (without Docker)
make dev
```

### Full Stack Development

For full stack development with backend:

1. Start backend first (in lv360-backend directory):
```bash
cd ../lv360-backend
make up
```

2. Then start frontend:
```bash
cd ../lv360-frontend
make dev-full
```

### Environment Variables

Copy `.env.local.example` to `.env.local` and configure:

```bash
COMPOSE_PROJECT_NAME=lv360_frontend_dev
VITE_API_URL=http://localhost:8000
VITE_ENVIRONMENT=development
```

### Docker Compose Files

- `docker-compose.local.yml` - Local development (frontend only)
- `docker-compose.dev.yml` - Dev server deployment

### Project Structure

```
frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── App.tsx
├── public/
├── nginx/
│   └── default.conf
├── package.json
├── Dockerfile.prod
└── vite.config.ts
```

### Deployment

Deploy to dev server:
```bash
make deploy-dev
```

### CI/CD

Jenkins pipeline automatically:
1. Runs tests
2. Builds Docker image
3. Pushes to Docker Hub
4. Deploys to dev server

### Troubleshooting

**Port conflicts:**
- Frontend uses port 3080
- Backend uses port 8000
- Postgres uses port 5432
- Redis uses port 6379

**Container issues:**
```bash
# Check container status
docker ps

# View logs
make logs

# Restart services
make down && make up
```

**Build issues:**
```bash
# Rebuild without cache
docker compose -f docker-compose.local.yml build --no-cache

# Clean up
make clean
```

### Contributing

1. Fork the repository
2. Create feature branch
3. Make changes
4. Run tests and linting
5. Submit pull request

### License

MIT License - see LICENSE file for details.
