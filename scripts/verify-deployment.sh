#!/bin/bash
# Deployment verification script for lv360-frontend
# Verifies that frontend can communicate with backend

set -e

echo "=== Verifying lv360-frontend Deployment ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        exit 1
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if frontend container is running
echo "1. Checking frontend container status..."
if docker ps | grep -q "lv360_frontend_dev"; then
    print_status 0 "Frontend container is running"
else
    print_status 1 "Frontend container is not running"
fi

# Check if backend container is running
echo "2. Checking backend container status..."
if docker ps | grep -q "lv360_backend_dev"; then
    print_status 0 "Backend container is running"
else
    print_status 1 "Backend container is not running"
fi

# Check shared network
echo "3. Checking shared network..."
if docker network ls | grep -q "lv360-shared-network"; then
    print_status 0 "Shared network exists"
else
    print_status 1 "Shared network does not exist"
fi

# Check if containers are connected to shared network
echo "4. Checking network connectivity..."
FRONTEND_CONNECTED=$(docker network inspect lv360-shared-network | grep -c "lv360_frontend_dev" || true)
BACKEND_CONNECTED=$(docker network inspect lv360-shared-network | grep -c "lv360_backend_dev" || true)

if [ "$FRONTEND_CONNECTED" -gt 0 ] && [ "$BACKEND_CONNECTED" -gt 0 ]; then
    print_status 0 "Both containers connected to shared network"
else
    print_warning "Network connectivity issue - Frontend: $FRONTEND_CONNECTED, Backend: $BACKEND_CONNECTED"
    echo "Connecting containers to shared network..."
    docker network connect lv360-shared-network lv360_frontend_dev 2>/dev/null || true
    docker network connect lv360-shared-network lv360_backend_dev 2>/dev/null || true
fi

# Test frontend health endpoint
echo "5. Testing frontend health endpoint..."
if curl -f -s http://localhost:3080/ > /dev/null; then
    print_status 0 "Frontend health check passed"
else
    print_status 1 "Frontend health check failed"
fi

# Test backend directly
echo "6. Testing backend directly..."
if curl -f -s http://localhost:8000/ > /dev/null; then
    print_status 0 "Backend is accessible directly"
else
    print_warning "Backend not accessible directly (might be expected)"
fi

# Test API proxy from frontend container
echo "7. Testing API proxy from frontend container..."
if docker exec lv360_frontend_dev curl -f -s http://lv360_backend_dev:8000/api/hello-db > /dev/null 2>&1; then
    print_status 0 "API proxy works from frontend container"
else
    print_status 1 "API proxy failed from frontend container"
fi

# Test external API endpoints
echo "8. Testing external API endpoints..."
if curl -f -s http://localhost:3080/api/hello-db > /dev/null; then
    print_status 0 "External API endpoint /api/hello-db works"
else
    print_status 1 "External API endpoint /api/hello-db failed"
fi

if curl -f -s http://localhost:3080/api/hello-cache > /dev/null; then
    print_status 0 "External API endpoint /api/hello-cache works"
else
    print_status 1 "External API endpoint /api/hello-cache failed"
fi

if curl -f -s http://localhost:3080/tasks > /dev/null; then
    print_status 0 "External API endpoint /tasks works"
else
    print_status 1 "External API endpoint /tasks failed"
fi

# Check nginx configuration
echo "9. Checking nginx configuration..."
if docker exec lv360_frontend_dev nginx -t > /dev/null 2>&1; then
    print_status 0 "Nginx configuration is valid"
else
    print_status 1 "Nginx configuration is invalid"
    docker exec lv360_frontend_dev nginx -t
fi

# Check container logs for errors
echo "10. Checking for recent errors..."
ERROR_COUNT=$(docker logs lv360_frontend_dev --since=5m 2>&1 | grep -i error | wc -l || true)
if [ "$ERROR_COUNT" -eq 0 ]; then
    print_status 0 "No recent errors in frontend logs"
else
    print_warning "$ERROR_COUNT errors found in recent logs"
    docker logs lv360_frontend_dev --since=5m 2>&1 | grep -i error | tail -5
fi

echo ""
echo "=== Deployment Verification Complete ==="
echo ""
echo "🌐 Frontend URL: http://localhost:3080/"
echo "🌐 Production URL: https://appdev.lamviec360.com/"
echo "🔧 Backend URL: http://localhost:8000/"
echo ""
echo "If all checks passed, the deployment is working correctly!"
