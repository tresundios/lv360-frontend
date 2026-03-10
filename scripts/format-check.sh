#!/bin/bash
# Format check script for lv360-frontend
# Run this before committing to ensure formatting is correct

set -e

echo "=== Running Format Check ==="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if we're in the frontend directory
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ Error: Must run from frontend directory${NC}"
    echo "Usage: cd frontend && ./scripts/format-check.sh"
    exit 1
fi

echo "1. Running Prettier format check..."
if npm run format:check; then
    echo -e "${GREEN}✅ Prettier formatting is correct${NC}"
else
    echo -e "${YELLOW}⚠️  Formatting issues found. Running auto-format...${NC}"
    npm run format
    echo -e "${GREEN}✅ Code has been auto-formatted${NC}"
    echo -e "${YELLOW}⚠️  Please review the changes and commit again${NC}"
    exit 1
fi

echo "2. Running ESLint..."
if npm run lint; then
    echo -e "${GREEN}✅ ESLint passed${NC}"
else
    echo -e "${RED}❌ ESLint failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ All format checks passed!${NC}"
echo "You can safely commit your changes."
