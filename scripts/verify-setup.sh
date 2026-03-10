#!/bin/bash
# Verification script for lv360-frontend deployment
# Run this to verify all configurations are correct

set -e

echo "=== Verifying lv360-frontend Configuration ==="
echo ""

# Check local files
echo "1. Checking local configuration files..."

# Check Jenkinsfile
if grep -q "/opt/lamviec360-frontend" Jenkinsfile.frontend; then
    echo "✅ Jenkinsfile.frontend has correct project directory"
else
    echo "❌ Jenkinsfile.frontend has incorrect project directory"
    exit 1
fi

# Check setup script
if grep -q "/opt/lamviec360-frontend" scripts/setup-deploy-server.sh; then
    echo "✅ setup-deploy-server.sh has correct project directory"
else
    echo "❌ setup-deploy-server.sh has incorrect project directory"
    exit 1
fi

# Check documentation
if grep -q "/opt/lamviec360-frontend" JENKINS-SETUP.md; then
    echo "✅ JENKINS-SETUP.md has correct project directory"
else
    echo "❌ JENKINS-SETUP.md has incorrect project directory"
    exit 1
fi

echo ""
echo "2. Checking Docker Compose configuration..."

# Check compose file
if grep -q "DOCKER_IMAGE_TAG" docker-compose.dev.yml; then
    echo "✅ docker-compose.dev.yml has DOCKER_IMAGE_TAG variable"
else
    echo "❌ docker-compose.dev.yml missing DOCKER_IMAGE_TAG variable"
    exit 1
fi

# Check environment file
if grep -q "DOCKER_IMAGE_TAG" .env.dev; then
    echo "✅ .env.dev has DOCKER_IMAGE_TAG variable"
else
    echo "❌ .env.dev missing DOCKER_IMAGE_TAG variable"
    exit 1
fi

echo ""
echo "3. Checking Nginx configuration..."

# Check production nginx config
if grep -q "lv360_backend_dev-backend-1:8000" frontend/nginx/default.prod.conf; then
    echo "✅ Production nginx config has correct backend URL"
else
    echo "❌ Production nginx config has incorrect backend URL"
    exit 1
fi

echo ""
echo "4. Checking Dockerfile configuration..."

# Check Dockerfile
if grep -q "NGINX_CONFIG" frontend/Dockerfile.prod; then
    echo "✅ Dockerfile.prod has NGINX_CONFIG argument"
else
    echo "❌ Dockerfile.prod missing NGINX_CONFIG argument"
    exit 1
fi

echo ""
echo "5. Checking Jenkins pipeline configuration..."

# Check Jenkinsfile for service name
if grep -q "docker compose.*up -d.*frontend" Jenkinsfile.frontend; then
    echo "✅ Jenkinsfile.frontend uses correct service name"
else
    echo "❌ Jenkinsfile.frontend has incorrect service name"
    exit 1
fi

# Check Jenkinsfile for directory references
if grep -q "dir('.')" Jenkinsfile.frontend; then
    echo "✅ Jenkinsfile.frontend has correct directory references"
else
    echo "❌ Jenkinsfile.frontend has incorrect directory references"
    exit 1
fi

echo ""
echo "6. Checking deployment scripts..."

# Check if setup script is executable
if [ -x "scripts/setup-deploy-server.sh" ]; then
    echo "✅ setup-deploy-server.sh is executable"
else
    echo "⚠️  setup-deploy-server.sh is not executable (fixing...)"
    chmod +x scripts/setup-deploy-server.sh
    echo "✅ setup-deploy-server.sh is now executable"
fi

echo ""
echo "=== All Configuration Checks Passed! ==="
echo ""
echo "Next steps:"
echo "1. SSH to deploy server: ssh deploy@103.175.146.37"
echo "2. Run setup script: /tmp/setup-deploy-server.sh"
echo "3. Test Jenkins pipeline: https://jenkins.lamviec360.com/job/lv360-frontend/"
echo "4. Verify deployment: https://appdev.lamviec360.com/"
