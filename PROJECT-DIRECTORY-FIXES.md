# Project Directory Corrections Applied

## Issue Identified
The deploy server project directory was incorrectly set to `/opt/lamviec360` but should be `/opt/lamviec360-frontend` for the frontend-only repository.

## Files Fixed

### 1. Configuration Files
- **scripts/setup-deploy-server.sh**: 
  - `PROJECT_DIR="/opt/lamviec360"` → `PROJECT_DIR="/opt/lamviec360-frontend"`
  - Repository check: `lv360-frontend` directory → `.git` directory
  - Monitoring script path: `/opt/lamviec360` → `/opt/lamviec360-frontend`

### 2. Jenkins Pipeline
- **Jenkinsfile.frontend**:
  - `REMOTE_PROJECT_DIR='/opt/lamviec360'` → `REMOTE_PROJECT_DIR='/opt/lamviec360-frontend'`

### 3. Documentation
- **JENKINS-SETUP.md**:
  - Project Directory: `/opt/lamviec360` → `/opt/lamviec360-frontend`
  - Manual deployment commands updated

- **FIXES-APPLIED.md**:
  - Jenkins Pipeline Variables updated
  - Manual deployment commands updated

### 4. Verification
- **scripts/verify-setup.sh**: Created comprehensive verification script
- **scripts/setup-deploy-server.sh**: Updated and made executable

## Deployment Server Structure

### Correct Directory Structure
```
/opt/lamviec360-frontend/          # Frontend project directory
├── .env.dev                      # Environment variables
├── docker-compose.dev.yml        # Docker compose configuration
├── frontend/                     # Frontend application code
│   ├── nginx/
│   ├── src/
│   └── ...
├── scripts/                      # Deployment scripts
└── monitor-frontend.sh          # Monitoring script
```

### Shared Network Configuration
```
lv360-shared-network              # Docker network
├── lv360_frontend_dev           # Frontend container
└── lv360_backend_dev-backend-1  # Backend container (from separate repo)
```

## Commands to Deploy

### 1. Copy Setup Script to Server
```bash
scp scripts/setup-deploy-server.sh deploy@103.175.146.37:/tmp/
```

### 2. SSH and Run Setup
```bash
ssh deploy@103.175.146.37
chmod +x /tmp/setup-deploy-server.sh
/tmp/setup-deploy-server.sh
```

### 3. Manual Deployment (if needed)
```bash
ssh deploy@103.175.146.37
cd /opt/lamviec360-frontend
git pull origin main
docker compose -f docker-compose.dev.yml up -d --no-deps --force-recreate frontend
```

### 4. Verify Deployment
```bash
# On deploy server
docker ps | grep lv360_frontend_dev
curl http://localhost:3080/

# From external
curl https://appdev.lamviec360.com/
```

## Jenkins Pipeline Flow

### Updated Deployment Steps
1. **SSH to deploy server**: `deploy@103.175.146.37`
2. **Navigate to project**: `cd /opt/lamviec360-frontend`
3. **Pull latest code**: `git pull origin main`
4. **Update image tag**: `sed -i 's|DOCKER_IMAGE_TAG=.*|DOCKER_IMAGE_TAG=${IMAGE_TAG}|' .env.dev`
5. **Create shared network**: `docker network create lv360-shared-network`
6. **Deploy frontend**: `docker compose -f docker-compose.dev.yml up -d --no-deps --force-recreate frontend`
7. **Connect to network**: `docker network connect lv360-shared-network lv360_frontend_dev`
8. **Health check**: `curl http://localhost:3080/`

## Environment Variables

### .env.dev (Correct)
```env
COMPOSE_PROJECT_NAME=lv360_frontend_dev
VITE_API_URL=https://dev.lamviec360.com
VITE_ENVIRONMENT=development
DOCKER_IMAGE_TAG=dev-latest
```

### Jenkins Environment
```bash
REMOTE_PROJECT_DIR=/opt/lamviec360-frontend
DEPLOY_HOST_dev=103.175.146.37
COMPOSE_FILE=docker-compose.dev.yml
```

## Monitoring and Maintenance

### Monitoring Script Location
- **Path**: `/opt/lamviec360-frontend/monitor-frontend.sh`
- **Cron**: Every 5 minutes
- **Actions**: Restart container if down, health check endpoint

### Log Rotation
- **Path**: `/etc/logrotate.d/lv360-frontend`
- **Retention**: 7 days
- **Frequency**: Daily

## Verification

### Local Verification
```bash
./scripts/verify-setup.sh
```

### Server Verification
```bash
ssh deploy@103.175.146.37
cd /opt/lamviec360-frontend
docker ps | grep lv360_frontend_dev
curl http://localhost:3080/
```

## URLs and Access

### Development
- **Local**: http://localhost:3080/
- **Deploy Server**: http://103.175.146.37:3080/
- **Production URL**: https://appdev.lamviec360.com/

### Jenkins
- **Jenkins Server**: https://jenkins.lamviec360.com/
- **Pipeline**: https://jenkins.lamviec360.com/job/lv360-frontend/
- **Jenkins IP**: 103.175.146.36

### Backend Communication
- **Shared Network**: lv360-shared-network
- **Backend Container**: lv360_backend_dev-backend-1:8000
- **API Endpoints**: /api/ and /tasks

## Troubleshooting

### Common Issues
1. **502 Bad Gateway**: Check if backend container is running and connected to shared network
2. **Container not starting**: Check logs with `docker logs lv360_frontend_dev`
3. **Port conflicts**: Ensure port 3080 is available
4. **Permission issues**: Verify deploy user has Docker access

### Quick Fixes
```bash
# Restart frontend
docker restart lv360_frontend_dev

# Recreate container
docker compose -f docker-compose.dev.yml up -d --force-recreate frontend

# Check network connectivity
docker network inspect lv360-shared-network
```

## Summary

All project directory references have been corrected from `/opt/lamviec360` to `/opt/lamviec360-frontend`. The deployment scripts, Jenkins pipeline, and documentation have been updated accordingly. The setup script has been copied to the deploy server and is ready for execution.

The verification script confirms all configurations are correct and ready for deployment.
