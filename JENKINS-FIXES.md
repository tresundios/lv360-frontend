# Jenkins Pipeline Fixes Applied

## Issue Identified
The Jenkins pipeline was failing because it couldn't find `package.json` and `package-lock.json` files. The pipeline was looking in the root directory, but these files are located in the `frontend/` subdirectory.

## Root Cause
The repository structure has the frontend application in a `frontend/` subdirectory:
```
lv360-frontend/
├── frontend/           # Application code
│   ├── package.json
│   ├── package-lock.json
│   ├── src/
│   └── ...
├── docker-compose.dev.yml
├── .env.dev
├── Jenkinsfile.frontend
└── scripts/
```

## Fixes Applied

### 1. Install & Lint Stage
**Before:**
```groovy
dir('.') {
    sh '''
        docker build ... .
        # COPY package.json package-lock.json ./
    '''
}
```

**After:**
```groovy
dir('frontend') {
    sh '''
        docker build ... .
        # COPY package.json package-lock.json ./
    '''
}
```

### 2. Test Stage
**Before:**
```groovy
dir('.') {
    sh '''
        docker run --rm lv360-frontend-lint:${BUILD_NUMBER} npm run test:ci
    '''
}
```

**After:**
```groovy
dir('frontend') {
    sh '''
        docker run --rm lv360-frontend-lint:${BUILD_NUMBER} npm run test:ci
    '''
}
```

### 3. Path-Based Trigger Logic
**Before:**
```groovy
def frontendRelevant = changedFiles.split('\n').any { file ->
    file.startsWith('src/') ||
    file.startsWith('frontend/') ||
    file == 'package.json' ||
    file == 'package-lock.json'
}
```

**After:**
```groovy
def frontendRelevant = changedFiles.split('\n').any { file ->
    file.startsWith('frontend/src/') ||
    file.startsWith('frontend/') ||
    file == 'frontend/package.json' ||
    file == 'frontend/package-lock.json' ||
    file == '.env.dev' ||
    file == '.env.local'
}
```

### 4. Test Results Path
**Before:**
```groovy
junit allowEmptyResults: true, testResults: '**/test-results.xml'
```

**After:**
```groovy
junit allowEmptyResults: true, testResults: 'frontend/**/test-results.xml'
```

### 5. Verification Script
Updated to check for correct directory references:
```bash
# Check Jenkinsfile for directory references
if grep -q "dir('frontend')" Jenkinsfile.frontend; then
    echo "✅ Jenkinsfile.frontend has correct directory references"
fi
```

## Docker Build Context

### Working Directory Structure
The Docker build now runs from within the `frontend/` directory, so:
- `COPY package.json package-lock.json ./` works correctly
- `COPY . .` copies the entire frontend application
- All npm commands run in the correct context

### Container Build Process
1. Jenkins runs in `/var/jenkins_home/workspace/lv360-frontend/`
2. Changes to `frontend/` directory for build stages
3. Docker build context is `frontend/`
4. Container has access to all frontend files

## Pipeline Flow After Fixes

### Stage 1: Checkout
- ✅ Checks out code to workspace
- ✅ Detects changes in frontend files correctly

### Stage 2: Install & Lint
- ✅ Changes to `frontend/` directory
- ✅ Builds lint container with correct context
- ✅ Runs `npm run lint` and `npm run format:check`

### Stage 3: Test
- ✅ Changes to `frontend/` directory
- ✅ Runs `npm run test:ci`
- ✅ Publishes test results from `frontend/**/test-results.xml`

### Stage 4: Docker Build
- ✅ Changes to `frontend/` directory
- ✅ Builds production image with correct Dockerfile
- ✅ Uses environment-specific VITE configuration

### Stage 5: Docker Push
- ✅ Pushes to Docker Hub registry
- ✅ Tags with build number and environment

### Stage 6: Deploy
- ✅ SSH to deploy server
- ✅ Pulls latest code (preserves directory structure)
- ✅ Updates and restarts frontend container

## File Context in Jenkins

### Workspace Structure
```
/var/jenkins_home/workspace/lv360-frontend/
├── frontend/
│   ├── package.json ✅
│   ├── package-lock.json ✅
│   ├── src/
│   ├── Dockerfile.prod
│   └── nginx/
├── docker-compose.dev.yml
├── .env.dev
├── Jenkinsfile.frontend
└── scripts/
```

### Docker Build Commands
```bash
# From Jenkins workspace
cd /var/jenkins_home/workspace/lv360-frontend/frontend
docker build -f Dockerfile.prod -t image:tag .
```

## Verification

### All Checks Pass
```bash
./scripts/verify-setup.sh
✅ Jenkinsfile.frontend has correct project directory
✅ setup-deploy-server.sh has correct project directory
✅ JENKINS-SETUP.md has correct project directory
✅ docker-compose.dev.yml has DOCKER_IMAGE_TAG variable
✅ .env.dev has DOCKER_IMAGE_TAG variable
✅ Production nginx config has correct backend URL
✅ Dockerfile.prod has NGINX_CONFIG argument
✅ Jenkinsfile.frontend uses correct service name
✅ Jenkinsfile.frontend has correct directory references
✅ setup-deploy-server.sh is executable
```

## Expected Jenkins Output

### Successful Build
```
[Pipeline] stage (Install & Lint)
[Pipeline] dir
Running in /var/jenkins_home/workspace/lv360-frontend/frontend
[Pipeline] sh
+ docker build -f - -t lv360-frontend-lint:13 .
Sending build context to Docker daemon  1.154MB
Step 1/5 : FROM node:20-alpine
Step 2/5 : WORKDIR /app
Step 3/5 : COPY package.json package-lock.json ./
Step 4/5 : RUN npm ci --prefer-offline --no-audit
Step 5/5 : COPY . .
Successfully built 1234567890abc
+ docker run --rm lv360-frontend-lint:13 npm run lint
✅ ESLint passed
+ docker run --rm lv360-frontend-lint:13 npm run format:check
✅ Prettier check passed
```

## Troubleshooting

### If Build Still Fails
1. **Check file structure**: Ensure `frontend/package.json` exists
2. **Check permissions**: Ensure Jenkins can read all files
3. **Check Docker context**: Verify build context is correct
4. **Check npm scripts**: Verify `lint`, `format:check`, `test:ci` exist

### Common Issues
1. **Missing files**: `frontend/package.json` not found
2. **Wrong directory**: Build running from wrong directory
3. **Permission errors**: Jenkins can't access files
4. **Docker context**: Build context doesn't include required files

## Next Steps

1. ✅ Fixes applied and pushed to GitHub
2. ✅ Verification script confirms all configurations
3. 🔄 Test Jenkins pipeline: https://jenkins.lamviec360.com/job/lv360-frontend/
4. 🔄 Verify deployment: https://appdev.lamviec360.com/

## Summary

The Jenkins pipeline has been fixed to properly handle the frontend subdirectory structure. All stages now use the correct working directory, and the build context includes all necessary files. The pipeline should now run successfully without the "file not found" errors.
