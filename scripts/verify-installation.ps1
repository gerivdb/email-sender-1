# Script de Vérification d'Installation
# Vérifie que tous les composants sont correctement installés et configurés

param(
   [switch]$Verbose,
   [switch]$FixIssues
)

Write-Host "🔍 Vérification Installation Planning Ecosystem Sync..." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

$script:errors = @()
$script:warnings = @()
$script:checks = 0
$script:passed = 0

function Test-Component {
   param(
      [string]$Name,
      [scriptblock]$TestScript,
      [scriptblock]$FixScript = $null
   )
    
   $script:checks++
   Write-Host "[$script:checks] Testing $Name..." -NoNewline
    
   try {
      $result = & $TestScript
      if ($result) {
         Write-Host " ✅" -ForegroundColor Green
         $script:passed++
         if ($Verbose) {
            Write-Host "    $result" -ForegroundColor Gray
         }
      }
      else {
         Write-Host " ❌" -ForegroundColor Red
         $script:errors += "Failed: $Name"
            
         if ($FixIssues -and $FixScript) {
            Write-Host "    Attempting fix..." -ForegroundColor Yellow
            & $FixScript
         }
      }
   }
   catch {
      Write-Host " ❌" -ForegroundColor Red
      $script:errors += "Error in $Name : $_"
   }
}

# Test 1: Go Installation
Test-Component "Go Installation" {
   $goVersion = go version 2>$null
   if ($goVersion -match "go(\d+\.\d+)") {
      $version = [version]$matches[1]
      if ($version -ge [version]"1.21") {
         return "Go $($matches[1]) installed"
      }
   }
   return $false
} {
   Write-Host "    Please install Go 1.21+ from https://golang.org/dl/"
}

# Test 2: Go Module Dependencies
Test-Component "Go Dependencies" {
   $modCheck = go mod verify 2>$null
   if ($LASTEXITCODE -eq 0) {
      return "All Go modules verified"
   }
   return $false
} {
   Write-Host "    Running go mod download..."
   go mod download
}

# Test 3: PostgreSQL Connection
Test-Component "PostgreSQL Connection" {
   try {
      $result = psql -U sync_user -d planning_sync -c "SELECT version();" 2>$null
      if ($LASTEXITCODE -eq 0) {
         return "PostgreSQL connected successfully"
      }
   }
   catch {}
   return $false
} {
   Write-Host "    Please ensure PostgreSQL is running and configured"
   Write-Host "    Run: psql -U postgres -c `"CREATE DATABASE planning_sync;`""
}

# Test 4: QDrant Connection
Test-Component "QDrant Vector DB" {
   try {
      $response = Invoke-RestMethod -Uri "http://localhost:6333/health" -TimeoutSec 5
      if ($response) {
         return "QDrant connected successfully"
      }
   }
   catch {}
   return $false
} {
   Write-Host "    Starting QDrant via Docker..."
   docker run -d -p 6333:6333 qdrant/qdrant:latest
}

# Test 5: Configuration Files
Test-Component "Configuration Files" {
   $configFiles = @("config.yaml", "alerts.yaml")
   $missing = @()
    
   foreach ($file in $configFiles) {
      if (!(Test-Path "config/$file")) {
         $missing += $file
      }
   }
    
   if ($missing.Count -eq 0) {
      return "All configuration files present"
   }
   else {
      return $false
   }
} {
   Write-Host "    Copying example configurations..."
   Copy-Item "config/config.example.yaml" "config/config.yaml" -Force
   Copy-Item "config/alerts.example.yaml" "config/alerts.yaml" -Force
}

# Test 6: TaskMaster CLI
Test-Component "TaskMaster CLI" {
   try {
      $taskmaster = Get-Command "roadmap-cli" -ErrorAction SilentlyContinue
      if ($taskmaster) {
         return "TaskMaster CLI available"
      }
   }
   catch {}
   return $false
} {
   Write-Host "    Please install TaskMaster CLI or ensure it's in PATH"
}

# Test 7: Required Directories
Test-Component "Directory Structure" {
   $requiredDirs = @(
      "roadmaps/plans",
      "logs",
      "backups",
      "temp",
      "docs"
   )
    
   $missing = @()
   foreach ($dir in $requiredDirs) {
      if (!(Test-Path $dir)) {
         $missing += $dir
      }
   }
    
   if ($missing.Count -eq 0) {
      return "All required directories exist"
   }
   else {
      return $false
   }
} {
   $requiredDirs = @("roadmaps/plans", "logs", "backups", "temp", "docs")
   foreach ($dir in $requiredDirs) {
      New-Item -ItemType Directory -Path $dir -Force | Out-Null
   }
}

# Test 8: Build System
Test-Component "Build System" {
   $buildResult = go build -o planning-sync-server.exe ./cmd/server 2>$null
   if ($LASTEXITCODE -eq 0 -and (Test-Path "planning-sync-server.exe")) {
      return "Build successful"
   }
   return $false
} {
   Write-Host "    Fixing build issues..."
   go mod tidy
   go build -o planning-sync-server.exe ./cmd/server
}

# Test 9: Test Suite
Test-Component "Unit Tests" {
   $testResult = go test ./... -short 2>$null
   if ($LASTEXITCODE -eq 0) {
      return "Unit tests passed"
   }
   return $false
} {
   Write-Host "    Some tests failed - this may be expected in development"
}

# Test 10: API Server Start
Test-Component "API Server" {
   # Start server in background
   $serverProcess = Start-Process -FilePath ".\planning-sync-server.exe" -PassThru -WindowStyle Hidden
   Start-Sleep 5
    
   try {
      $health = Invoke-RestMethod -Uri "http://localhost:8080/health" -TimeoutSec 10
      $serverProcess | Stop-Process -Force
      if ($health.status -eq "healthy") {
         return "API server started successfully"
      }
   }
   catch {
      $serverProcess | Stop-Process -Force -ErrorAction SilentlyContinue
   }
   return $false
} {
   Write-Host "    Check server logs for detailed error information"
}

# Test 11: Sample Plan Validation
Test-Component "Plan Validation" {
   $samplePlan = "roadmaps/plans/plan-dev-v55-planning-ecosystem-sync.md"
   if (Test-Path $samplePlan) {
      $validationResult = go run tools/validation-engine.go -file $samplePlan 2>$null
      if ($LASTEXITCODE -eq 0) {
         return "Sample plan validation successful"
      }
   }
   return $false
} {
   Write-Host "    Ensure sample plans are properly formatted"
}

# Test 12: Dependencies Check
Test-Component "External Dependencies" {
   $deps = @{
      "git"    = "git --version"
      "docker" = "docker --version"
      "node"   = "node --version"
   }
    
   $missing = @()
   foreach ($dep in $deps.GetEnumerator()) {
      try {
         Invoke-Expression $dep.Value | Out-Null
         if ($LASTEXITCODE -ne 0) {
            $missing += $dep.Key
         }
      }
      catch {
         $missing += $dep.Key
      }
   }
    
   if ($missing.Count -eq 0) {
      return "All external dependencies available"
   }
   else {
      $script:warnings += "Missing optional dependencies: $($missing -join ', ')"
      return "Some optional dependencies missing but not critical"
   }
}

# Summary
Write-Host "`n📊 Installation Verification Summary" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host "✅ Passed: $script:passed/$script:checks checks" -ForegroundColor Green

if ($script:warnings.Count -gt 0) {
   Write-Host "⚠️  Warnings:" -ForegroundColor Yellow
   $script:warnings | ForEach-Object { Write-Host "   • $_" -ForegroundColor Yellow }
}

if ($script:errors.Count -gt 0) {
   Write-Host "❌ Errors:" -ForegroundColor Red
   $script:errors | ForEach-Object { Write-Host "   • $_" -ForegroundColor Red }
   Write-Host "`n🔧 Run with -FixIssues to attempt automatic fixes" -ForegroundColor Yellow
   exit 1
}
else {
   Write-Host "`n🎉 Installation complète et fonctionnelle !" -ForegroundColor Green
   Write-Host "💡 Next steps:" -ForegroundColor Cyan
   Write-Host "   1. Review configuration in config/config.yaml" -ForegroundColor Gray
   Write-Host "   2. Start the dashboard: .\planning-sync-server.exe" -ForegroundColor Gray
   Write-Host "   3. Visit http://localhost:8080/dashboard" -ForegroundColor Gray
   Write-Host "   4. Run your first sync: go run tools/plan-synchronizer.go" -ForegroundColor Gray
   exit 0
}
