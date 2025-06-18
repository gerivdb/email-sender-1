#!/usr/bin/env pwsh
# Environment Optimization Script

# Node.js optimizations
 = "--max-old-space-size=4096 --optimize-for-size"
 = "16"

# Graphics optimizations
 = "1"
 = "1"
 = "100"
 = "1"

# Performance optimizations
 = "1"
 = "1"
 = "--disable-gpu-sandbox --enable-gpu-rasterization"

Write-Host "Environment variables optimized for graphics and performance"
