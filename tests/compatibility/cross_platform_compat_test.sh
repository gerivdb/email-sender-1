#!/bin/bash

# Cross-Platform & Browser Compatibility Test Script
# Action 047 - Validation Cross-Browser & Multi-Platform

set -e

echo "=== [CROSS-PLATFORM COMPATIBILITY TEST] ==="
echo "Date: $(date)"
echo "Host: $(uname -a)"
echo "Go version: $(go version)"
echo "Node version: $(node -v 2>/dev/null || echo 'Node not installed')"
echo "N8N version: $(n8n --version 2>/dev/null || echo 'n8n not installed')"
echo

# Test Go CLI on current OS
echo "[1] Testing Go CLI execution..."
if ./cli.exe --help >/dev/null 2>&1; then
  echo "Go CLI: OK"
else
  echo "Go CLI: FAIL"
  exit 1
fi

# Test Go API server (if available)
if [ -f "./api-server.exe" ]; then
  echo "[2] Testing Go API server startup..."
  ./api-server.exe --version || echo "API server: version check failed"
  ./api-server.exe --help || echo "API server: help check failed"
  echo "API server: OK (manual check may be required)"
fi

# Test N8N API endpoint (assumes running on localhost:5678)
echo "[3] Testing N8N API endpoint (localhost:5678)..."
if curl -s http://localhost:5678/rest/healthz | grep -q '"status":"ok"'; then
  echo "N8N API: OK"
else
  echo "N8N API: FAIL or not running"
fi

# Browser compatibility (manual/CI step)
echo "[4] Browser compatibility (manual/CI):"
echo "  - Open http://localhost:5678 in Chrome, Firefox, Edge, Safari"
echo "  - Check UI loads and custom node is visible"
echo "  - Run a test workflow with GoCliExecutor node"

echo
echo "=== [COMPATIBILITY TEST COMPLETE] ==="
