#!/bin/bash
# Setup script for lv360-frontend deploy server
# Run this on the deploy server (103.175.146.37) as deploy user

set -e

echo "Setting up lv360-frontend deploy server..."

# Create project directory
PROJECT_DIR="/opt/lamviec360-frontend"
echo "Creating project directory: $PROJECT_DIR"
sudo mkdir -p $PROJECT_DIR
sudo chown deploy:deploy $PROJECT_DIR

# Navigate to project directory
cd $PROJECT_DIR

# Clone the frontend repository if not already present
if [ ! -d ".git" ]; then
    echo "Cloning lv360-frontend repository..."
    git clone https://github.com/tresundios/lv360-frontend.git .
else
    echo "Repository already exists, pulling latest..."
    git pull origin main
fi

# Create environment files if they don't exist
echo "Setting up environment files..."
if [ ! -f ".env.dev" ]; then
    cp .env.dev.example .env.dev
    echo "Created .env.dev - please review and update as needed"
fi

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker deploy
    rm get-docker.sh
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Create shared network for frontend-backend communication
echo "Creating shared network..."
docker network create lv360-shared-network 2>/dev/null || echo "Network already exists"

# Stop any existing containers
echo "Stopping existing containers..."
docker stop lv360_frontend_dev 2>/dev/null || true
docker rm lv360_frontend_dev 2>/dev/null || true

# Pull latest image
echo "Pulling latest frontend image..."
docker pull navistresundios/lamviec360-frontend:dev-latest

# Start frontend container
echo "Starting frontend container..."
docker compose -f docker-compose.dev.yml up -d

# Wait for container to be healthy
echo "Waiting for health check..."
sleep 10

# Check if deployment was successful
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

# Setup log rotation
echo "Setting up log rotation..."
sudo tee /etc/logrotate.d/lv360-frontend <<EOF
/var/lib/docker/containers/*/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
}
EOF

# Setup monitoring script
echo "Setting up monitoring script..."
cat > $PROJECT_DIR/monitor-frontend.sh << 'EOF'
#!/bin/bash
# Monitoring script for lv360-frontend

CONTAINER_NAME="lv360_frontend_dev"
HEALTH_URL="http://localhost:3080/"

# Check if container is running
if ! docker ps | grep -q $CONTAINER_NAME; then
    echo "Container $CONTAINER_NAME is not running. Starting..."
    cd /opt/lamviec360-frontend
    docker compose -f docker-compose.dev.yml up -d
    exit 1
fi

# Check health endpoint
if ! curl -f $HEALTH_URL >/dev/null 2>&1; then
    echo "Health check failed for $CONTAINER_NAME. Restarting..."
    docker restart $CONTAINER_NAME
    exit 1
fi

echo "Frontend is healthy"
EOF

chmod +x $PROJECT_DIR/monitor-frontend.sh

# Add to crontab for monitoring every 5 minutes
(crontab -l 2>/dev/null; echo "*/5 * * * * $PROJECT_DIR/monitor-frontend.sh") | crontab -

echo "✅ Setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Verify the deployment: curl http://localhost:3080/"
echo "2. Check Jenkins pipeline access"
echo "3. Update environment variables as needed"
echo "4. Configure SSL certificate for https://appdev.lamviec360.com"
echo ""
echo "Frontend URL: http://localhost:3080/"
echo "Production URL: https://appdev.lamviec360.com/"
