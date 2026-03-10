#!/bin/bash
# Deployment setup script for lv360-frontend on dev server
# This script ensures proper networking between frontend and backend containers

set -e

echo "Setting up lv360-frontend deployment..."

# Create shared network if it doesn't exist
if ! docker network ls | grep -q "lv360-shared-network"; then
    echo "Creating shared network..."
    docker network create lv360-shared-network
fi

# Stop any existing frontend container
echo "Stopping existing frontend container..."
docker stop lv360_frontend_dev 2>/dev/null || true
docker rm lv360_frontend_dev 2>/dev/null || true

# Pull the latest image
echo "Pulling latest frontend image..."
docker pull navistresundios/lamviec360-frontend:${DOCKER_IMAGE_TAG:-dev-latest}

# Run frontend container on shared network
echo "Starting frontend container..."
docker run -d \
    --name lv360_frontend_dev \
    --network lv360-shared-network \
    -p 3080:80 \
    -e VITE_API_URL=https://dev.lamviec360.com \
    -e VITE_ENVIRONMENT=development \
    --restart unless-stopped \
    navistresundios/lamviec360-frontend:${DOCKER_IMAGE_TAG:-dev-latest}

echo "Frontend deployment completed!"
echo "Waiting for health check..."
sleep 10

# Check if container is running
if docker ps | grep -q "lv360_frontend_dev"; then
    echo "✅ Frontend container is running"
else
    echo "❌ Frontend container failed to start"
    docker logs lv360_frontend_dev
    exit 1
fi

# Test health endpoint
if curl -f http://localhost:3080/ >/dev/null 2>&1; then
    echo "✅ Frontend health check passed"
else
    echo "❌ Frontend health check failed"
    docker logs lv360_frontend_dev
    exit 1
fi

echo "🚀 Frontend deployment successful!"
