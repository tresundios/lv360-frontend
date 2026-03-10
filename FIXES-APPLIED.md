# Fixes Applied to lv360-frontend Jenkins Pipeline

## Issues Identified and Fixed

### 1. Jenkins Pipeline Issues

#### Problem: Directory Structure Mismatch
- **Issue**: Jenkinsfile expected `frontend/` directory but repo is now frontend-only
- **Fix**: Updated all `dir('frontend')` references to `dir('.')` in stages:
  - Install & Lint stage
  - Test stage
  - Docker Build stage (kept as 'frontend' for Dockerfile location)

#### Problem: Service Name Mismatch
- **Issue**: Jenkinsfile tried to restart `react` service but compose file has `frontend`
- **Fix**: Updated deployment script to restart `frontend` service

#### Problem: Environment File Path
- **Issue**: Jenkinsfile expected `env/.env.dev` but actual file is `.env.dev`
- **Fix**: Updated deployment script to use `.env.dev`

#### Problem: Git Branch Reference
- **Issue**: Jenkinsfile pulled from `${params.TARGET_ENV}` branch but should be `main`
- **Fix**: Updated to pull from `main` branch

### 2. 502 Bad Gateway Issues

#### Problem: Nginx Proxy Configuration
- **Issue**: Nginx used `host.docker.internal:8000` which doesn't work in production
- **Fix**: Created production nginx config (`default.prod.conf`) with correct backend URL

#### Problem: Backend Container Communication
- **Issue**: Frontend couldn't communicate with backend container
- **Fix**: 
  - Created shared network `lv360-shared-network`
  - Updated nginx proxy to use backend container name: `lv360_backend_dev-backend-1:8000`
  - Added network connection in deployment script

### 3. Docker Build Issues

#### Problem: Missing Production Nginx Config
- **Issue**: No production-specific nginx configuration
- **Fix**: Created `default.prod.conf` with production settings

#### Problem: Docker Build Arguments
- **Issue**: Nginx config was hardcoded
- **Fix**: Made nginx config configurable via build argument `NGINX_CONFIG`

#### Problem: Image Tag Management
- **Issue**: Image tag was hardcoded in compose file
- **Fix**: Added `DOCKER_IMAGE_TAG` environment variable to compose file

## Files Modified

### 1. Jenkins Configuration
- **Jenkinsfile.frontend**: Fixed directory references, service names, and deployment logic
- **.env.dev**: Added `DOCKER_IMAGE_TAG` variable
- **docker-compose.dev.yml**: Made image tag configurable

### 2. Docker Configuration
- **Dockerfile.prod**: Added configurable nginx config support
- **frontend/nginx/default.prod.conf**: Production nginx configuration

### 3. Deployment Scripts
- **scripts/setup-deploy-server.sh**: Complete server setup script
- **scripts/deploy-setup.sh**: Deployment automation script

### 4. Documentation
- **JENKINS-SETUP.md**: Comprehensive Jenkins setup guide
- **FIXES-APPLIED.md**: This document

## Deployment Architecture

### Before (Broken)
```
Frontend (nginx) → host.docker.internal:8000 (doesn't work in production)
```

### After (Fixed)
```
Frontend (nginx) → lv360_backend_dev-backend-1:8000 (shared network)
```

### Network Configuration
- **Shared Network**: `lv360-shared-network`
- **Frontend Container**: `lv360_frontend_dev`
- **Backend Container**: `lv360_backend_dev-backend-1`
- **Communication**: Docker internal network via container names

## Environment Variables

### Development (.env.dev)
```env
COMPOSE_PROJECT_NAME=lv360_frontend_dev
VITE_API_URL=https://dev.lamviec360.com
VITE_ENVIRONMENT=development
DOCKER_IMAGE_TAG=dev-latest
```

### Jenkins Pipeline Variables
```bash
DOCKER_REGISTRY=docker.io
DOCKER_REPO=navistresundios/lamviec360-frontend
IMAGE_TAG=dev-{BUILD_NUMBER}
DEPLOY_HOST_dev=103.175.146.37
REMOTE_PROJECT_DIR=/opt/lamviec360-frontend
```

## Nginx Proxy Configuration

### Production (default.prod.conf)
```nginx
# API endpoints
location /api/ {
    proxy_pass http://lv360_backend_dev-backend-1:8000/api/;
    # ... headers
}

# Tasks endpoints  
location /tasks {
    proxy_pass http://lv360_backend_dev-backend-1:8000;
    # ... headers
}
```

## Deployment Process

### Jenkins Pipeline Flow
1. **Checkout**: Pull code, check for relevant changes
2. **Install & Lint**: Build lint container, run linting
3. **Test**: Run unit tests, publish results
4. **Docker Build**: Build production image with environment config
5. **Docker Push**: Push to Docker Hub registry
6. **Deploy**: SSH to deploy server, update and restart container

### Manual Deployment Commands
```bash
# SSH to deploy server
ssh deploy@103.175.146.37

# Navigate to project
cd /opt/lamviec360-frontend

# Update and deploy
git pull origin main
docker compose -f docker-compose.dev.yml up -d --no-deps --force-recreate frontend
docker network connect lv360-shared-network lv360_frontend_dev
```

## Troubleshooting Guide

### 502 Bad Gateway
1. Check backend container: `docker ps | grep backend`
2. Verify shared network: `docker network ls | grep lv360-shared-network`
3. Test backend connectivity: `curl http://lv360_backend_dev-backend-1:8000/`
4. Check nginx config: `docker exec lv360_frontend_dev nginx -t`

### Jenkins Pipeline Failures
1. Verify Docker Hub credentials in Jenkins
2. Check SSH key access to deploy server
3. Ensure environment files exist on deploy server
4. Verify image pull permissions

### Container Not Starting
1. Check container logs: `docker logs lv360_frontend_dev`
2. Verify port availability: `netstat -tlnp | grep 3080`
3. Check Docker daemon status: `systemctl status docker`

## Verification Steps

### 1. Local Testing
```bash
# Build and run locally
docker compose -f docker-compose.local.yml up -d

# Test endpoints
curl http://localhost:3080/
curl http://localhost:3080/api/hello-db
curl http://localhost:3080/api/hello-cache
curl http://localhost:3080/tasks
```

### 2. Production Testing
```bash
# On deploy server
curl http://localhost:3080/
curl https://appdev.lamviec360.com/

# Check container status
docker ps | grep lv360_frontend_dev
docker logs lv360_frontend_dev
```

### 3. Jenkins Pipeline Testing
1. Trigger pipeline manually
2. Check each stage for success
3. Verify deployment on server
4. Test application endpoints

## Security Considerations

1. **Credentials**: Store in Jenkins Credentials Store
2. **SSH Keys**: Use key-based authentication
3. **Environment Variables**: Don't expose sensitive data
4. **Network Security**: Use Docker networks for isolation
5. **SSL/TLS**: Configure for production URLs

## Monitoring and Maintenance

1. **Health Checks**: Container health every 30 seconds
2. **Log Rotation**: Daily rotation, 7-day retention
3. **Automated Monitoring**: Cron job every 5 minutes
4. **Alerting**: Jenkins pipeline failure notifications

## Next Steps

1. Apply these fixes to the repository
2. Run the setup script on deploy server
3. Test Jenkins pipeline
4. Verify application functionality
5. Configure SSL certificate for production URL
6. Set up monitoring and alerting

## Contact Information

- **Jenkins Server**: https://jenkins.lamviec360.com/
- **Deploy Server**: 103.175.146.37
- **Application URL**: https://appdev.lamviec360.com/
- **Support: dev team
