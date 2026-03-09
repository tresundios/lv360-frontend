#!/bin/bash

echo "🚀 Setting up LV360 Frontend development environment..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create necessary directories
mkdir -p logs data

# Copy environment file if it doesn't exist
if [ ! -f .env.local ]; then
    cp .env.local.example .env.local
    echo "✅ Created .env.local from example"
fi

# Build and start services
echo "📦 Building Docker image..."
docker compose -f docker-compose.local.yml --env-file .env.local build

echo "🚀 Starting frontend service..."
docker compose -f docker-compose.local.yml --env-file .env.local up -d

# Wait for service to be ready
echo "⏳ Waiting for frontend to start..."
sleep 10

# Check if service is running
if curl -f http://localhost:3080/ > /dev/null 2>&1; then
    echo "✅ Frontend is running at http://localhost:3080"
else
    echo "❌ Frontend failed to start. Check logs with 'make logs'"
    exit 1
fi

echo ""
echo "🎉 Frontend development environment is ready!"
echo ""
echo "📝 Available commands:"
echo "  make up      - Start services"
echo "  make down    - Stop services"
echo "  make logs    - View logs"
echo "  make test    - Run tests"
echo "  make lint    - Run linting"
echo "  make dev     - Start development server"
echo ""
echo "🌐 Access your app at: http://localhost:3080"
