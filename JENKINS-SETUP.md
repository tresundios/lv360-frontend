# Jenkins Setup for lv360-frontend

## Overview
This document explains the Jenkins pipeline configuration for the lv360-frontend repository.

## Jenkins Configuration

### 1. Jenkins Server Details
- **URL**: https://jenkins.lamviec360.com/
- **IP**: 103.175.146.36
- **Job**: https://jenkins.lamviec360.com/job/lv360-frontend/

### 2. Deployment Server Details
- **IP**: 103.175.146.37
- **App URL**: https://appdev.lamviec360.com/
- **User**: deploy
- **Project Directory**: /opt/lamviec360-frontend

### 3. Required Jenkins Credentials

Configure these credentials in Jenkins Credentials Store:

#### Docker Hub Credentials
- **ID**: `dockerhub-credentials`
- **Type**: Username with password
- **Username**: Your Docker Hub username
- **Password**: Your Docker Hub password

#### SSH Credentials
- **ID**: `ssh-dev-server`
- **Type**: SSH Username with private key
- **Username**: deploy
- **Private Key**: Your SSH private key for the deploy server

### 4. Pipeline Parameters
- **TARGET_ENV**: dev, qa, uat, prod
- **SKIP_TESTS**: Boolean to skip tests (emergency deploys only)

### 5. Environment Variables in Pipeline
- `DOCKER_REGISTRY`: docker.io
- `DOCKER_REPO`: navistresundios/lamviec360-frontend
- `DEPLOY_HOST_dev`: 103.175.146.37
- `REMOTE_PROJECT_DIR`: /opt/lamviec360

### 6. Pipeline Stages

#### Stage 1: Checkout
- Checks out the code
- Determines if frontend-relevant files changed
- Skips pipeline if no relevant changes

#### Stage 2: Install & Lint
- Builds a temporary Docker container for linting
- Runs `npm run lint` and `npm run format:check`

#### Stage 3: Test
- Runs unit tests with `npm run test:ci`
- Publishes JUnit test results

#### Stage 4: Docker Build
- Builds production Docker image
- Uses environment-specific VITE configuration
- Tags image with build number and environment

#### Stage 5: Docker Push
- Pushes image to Docker Hub registry
- Tags both specific build and latest

#### Stage 6: Deploy
- Connects to deployment server via SSH
- Pulls latest code and Docker image
- Updates environment file with new image tag
- Creates shared network for frontend-backend communication
- Restarts frontend container
- Performs health check

### 7. Docker Compose Configuration

#### Development Environment (.env.dev)
```env
COMPOSE_PROJECT_NAME=lv360_frontend_dev
VITE_API_URL=https://dev.lamviec360.com
VITE_ENVIRONMENT=development
DOCKER_IMAGE_TAG=dev-latest
```

#### Docker Compose File (docker-compose.dev.yml)
- Uses environment variable for image tag
- Exposes port 3080
- Configured for production nginx

### 8. Network Configuration

#### Shared Network
- **Name**: lv360-shared-network
- **Purpose**: Allows frontend container to communicate with backend container
- **Created**: Automatically during deployment

#### Backend Container Name
- **Expected**: lv360_backend_dev-backend-1
- **Used in nginx proxy**: http://lv360_backend_dev-backend-1:8000

### 9. Troubleshooting

#### 502 Bad Gateway Error
1. Check if backend container is running: `docker ps | grep backend`
2. Verify shared network exists: `docker network ls | grep lv360-shared-network`
3. Check if frontend is connected to network: `docker network inspect lv360-shared-network`
4. Test backend connectivity: `curl http://lv360_backend_dev-backend-1:8000/`

#### Jenkins Pipeline Failures
1. Check Docker Hub credentials
2. Verify SSH key access to deploy server
3. Check if environment files exist on deploy server
4. Verify Docker image pull permissions

#### Health Check Failures
1. Check container logs: `docker logs lv360_frontend_dev`
2. Verify port 3080 is accessible: `curl -f http://localhost:3080/`
3. Check nginx configuration: `docker exec lv360_frontend_dev nginx -t`

### 10. Manual Deployment Commands

If Jenkins fails, you can deploy manually:

```bash
# SSH into deploy server
ssh deploy@103.175.146.37

# Navigate to project directory
cd /opt/lamviec360-frontend

# Pull latest code
git pull origin main

# Update image tag
sed -i 's|DOCKER_IMAGE_TAG=.*|DOCKER_IMAGE_TAG=dev-123|' .env.dev

# Export environment variables
set -a
source .env.dev
set +a

# Create shared network
docker network create lv360-shared-network 2>/dev/null || true

# Deploy frontend
docker compose -f docker-compose.dev.yml up -d --no-deps --force-recreate frontend

# Connect to shared network
docker network connect lv360-shared-network lv360_frontend_dev 2>/dev/null || true

# Check status
docker ps | grep frontend
curl -f http://localhost:3080/
```

### 11. Environment-Specific Configurations

#### Development (dev)
- **API URL**: https://dev.lamviec360.com
- **Environment**: development
- **Image Tag**: dev-{BUILD_NUMBER}

#### QA (qa)
- **API URL**: https://qa.lamviec360.com
- **Environment**: qa
- **Image Tag**: qa-{BUILD_NUMBER}

#### UAT (uat)
- **API URL**: https://uat.lamviec360.com
- **Environment**: uat
- **Image Tag**: uat-{BUILD_NUMBER}

#### Production (prod)
- **API URL**: https://api.lamviec360.com
- **Environment**: production
- **Image Tag**: prod-{BUILD_NUMBER}

### 12. Security Considerations
- All credentials stored in Jenkins Credentials Store
- SSH keys used for server access
- Docker Hub credentials for image push/pull
- Environment variables not exposed in logs
- Nginx security headers configured

### 13. Monitoring and Alerts
- Jenkins pipeline status notifications
- Health check failures trigger pipeline failure
- Container restart policy: always
- Health check interval: 30 seconds
- Health check timeout: 10 seconds
- Health check retries: 3
