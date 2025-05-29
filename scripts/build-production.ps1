#!/usr/bin/env pwsh
# Production Build Script for Email Sender Native Deployment
# This script builds optimized binaries for production deployment without Docker

param(
    [string]$Target = "all",  # all, linux, windows, darwin
    [switch]$Compress = $true,
    [switch]$Deploy = $false,
    [string]$OutputDir = "dist",
    [switch]$Verbose = $false
)

# Set error handling
$ErrorActionPreference = "Stop"

# Build configuration
$BUILD_VERSION = (Get-Date -Format "yyyy.MM.dd.HHmm")
$PROJECT_ROOT = Split-Path -Parent $PSScriptRoot
$GO_MODULE = "email-sender"

# Build flags for optimization
$BUILD_FLAGS = @(
    "-ldflags",
    "-s -w -X main.version=$BUILD_VERSION -X main.buildTime=$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')",
    "-trimpath",
    "-tags", "netgo,osusergo"
)

# Platform configurations
$PLATFORMS = @{
    "linux"   = @{ OS = "linux"; ARCH = "amd64"; EXT = "" }
    "windows" = @{ OS = "windows"; ARCH = "amd64"; EXT = ".exe" }
    "darwin"  = @{ OS = "darwin"; ARCH = "amd64"; EXT = "" }
}

function Write-Status {
    param([string]$Message)
    Write-Host "🔄 $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Initialize-Build {
    Write-Status "Initializing production build environment..."
    
    # Change to project root
    Set-Location $PROJECT_ROOT
    
    # Create output directory
    if (Test-Path $OutputDir) {
        Remove-Item $OutputDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    
    # Verify Go environment
    try {
        $goVersion = go version
        Write-Status "Go version: $goVersion"
    }
    catch {
        Write-Error "Go is not installed or not in PATH"
        exit 1
    }
    
    # Clean previous builds
    Write-Status "Cleaning previous builds..."
    go clean -cache
    go mod tidy
    
    Write-Success "Build environment initialized"
}

function Build-Binary {
    param(
        [string]$Platform,
        [hashtable]$Config,
        [string]$MainPackage
    )
    
    $binaryName = "$GO_MODULE-$Platform$($Config.EXT)"
    $outputPath = Join-Path $OutputDir $binaryName
    
    Write-Status "Building $Platform binary: $binaryName"
    
    # Set environment variables for cross-compilation
    $env:GOOS = $Config.OS
    $env:GOARCH = $Config.ARCH
    $env:CGO_ENABLED = "0"
    
    try {
        # Build the binary
        $buildArgs = @("build") + $BUILD_FLAGS + @("-o", $outputPath, $MainPackage)
        
        if ($Verbose) {
            Write-Host "Build command: go $($buildArgs -join ' ')"
        }
        
        & go @buildArgs
        
        if ($LASTEXITCODE -eq 0) {
            $fileSize = (Get-Item $outputPath).Length
            Write-Success "Built $Platform binary: $binaryName ($([math]::Round($fileSize/1MB, 2)) MB)"
            
            # Compress with UPX if available and requested
            if ($Compress -and (Get-Command upx -ErrorAction SilentlyContinue)) {
                Write-Status "Compressing $binaryName with UPX..."
                upx --best --lzma $outputPath 2>$null
                if ($LASTEXITCODE -eq 0) {
                    $compressedSize = (Get-Item $outputPath).Length
                    $ratio = [math]::Round((1 - $compressedSize/$fileSize) * 100, 1)
                    Write-Success "Compressed $binaryName ($([math]::Round($compressedSize/1MB, 2)) MB, $ratio% reduction)"
                } else {
                    Write-Host "⚠️  UPX compression failed for $binaryName" -ForegroundColor Yellow
                }
            }
            
            return $true
        } else {
            Write-Error "Failed to build $Platform binary"
            return $false
        }
    }
    catch {
        Write-Error "Error building $Platform binary: $($_.Exception.Message)"
        return $false
    }
}

function Copy-Configs {
    Write-Status "Copying configuration files..."
    
    $configSrc = Join-Path $PROJECT_ROOT "configs"
    $configDst = Join-Path $OutputDir "configs"
    
    if (Test-Path $configSrc) {
        Copy-Item $configSrc $configDst -Recurse -Force
        Write-Success "Configuration files copied"
    }
    
    # Copy deployment scripts
    $scriptsSrc = Join-Path $PROJECT_ROOT "scripts\deployment"
    $scriptsDst = Join-Path $OutputDir "scripts"
    
    if (Test-Path $scriptsSrc) {
        Copy-Item $scriptsSrc $scriptsDst -Recurse -Force
        Write-Success "Deployment scripts copied"
    }
}

function Generate-DeploymentInfo {
    Write-Status "Generating deployment information..."
    
    $deployInfo = @{
        version = $BUILD_VERSION
        buildTime = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
        platforms = @()
        files = @()
    }
    
    Get-ChildItem $OutputDir -File | ForEach-Object {
        $deployInfo.files += @{
            name = $_.Name
            size = $_.Length
            hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
        }
    }
    
    $deployInfo.platforms = $PLATFORMS.Keys
    
    $deployInfoPath = Join-Path $OutputDir "deployment-info.json"
    $deployInfo | ConvertTo-Json -Depth 3 | Set-Content $deployInfoPath
    
    Write-Success "Deployment info generated: deployment-info.json"
}

function Create-SystemdService {
    Write-Status "Creating systemd service file..."
    
    $systemdService = @"
[Unit]
Description=Email Sender Service
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/opt/email-sender/email-sender-linux
WorkingDirectory=/opt/email-sender
Restart=always
RestartSec=5
User=emailsender
Group=emailsender

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/email-sender/logs /opt/email-sender/data

# Environment
Environment=EMAIL_SENDER_ENV=production
EnvironmentFile=-/opt/email-sender/configs/.env

[Install]
WantedBy=multi-user.target
"@
    
    $servicePath = Join-Path $OutputDir "email-sender.service"
    $systemdService | Set-Content $servicePath
    
    Write-Success "Systemd service file created"
}

function Create-WindowsService {
    Write-Status "Creating Windows service installer..."
    
    $serviceScript = @"
@echo off
echo Installing Email Sender Windows Service...

sc create EmailSender binpath= "C:\Program Files\EmailSender\email-sender-windows.exe" ^
    displayname= "Email Sender Service" ^
    description= "Native Email Sender Service" ^
    start= auto

sc config EmailSender obj= "NT AUTHORITY\LocalService"

echo Service installed. Starting service...
sc start EmailSender

echo.
echo Service installation complete.
echo You can manage the service using:
echo   sc start EmailSender
echo   sc stop EmailSender
echo   sc delete EmailSender
pause
"@
    
    $servicePath = Join-Path $OutputDir "install-windows-service.bat"
    $serviceScript | Set-Content $servicePath
    
    Write-Success "Windows service installer created"
}

function Main {
    Write-Host "🚀 Email Sender Production Build" -ForegroundColor Blue
    Write-Host "=================================" -ForegroundColor Blue
    
    Initialize-Build
    
    # Determine which platforms to build
    $platformsToBuild = @()
    if ($Target -eq "all") {
        $platformsToBuild = $PLATFORMS.Keys
    } elseif ($PLATFORMS.ContainsKey($Target)) {
        $platformsToBuild = @($Target)
    } else {
        Write-Error "Invalid target: $Target. Available targets: $($PLATFORMS.Keys -join ', '), all"
        exit 1
    }
    
    # Build main application
    $mainPackage = "./cmd/email-server"
    $buildSuccess = $true
    
    foreach ($platform in $platformsToBuild) {
        $success = Build-Binary -Platform $platform -Config $PLATFORMS[$platform] -MainPackage $mainPackage
        if (-not $success) {
            $buildSuccess = $false
        }
    }
    
    if (-not $buildSuccess) {
        Write-Error "Some builds failed"
        exit 1
    }
    
    # Build additional tools
    $tools = @{
        "config-manager" = "./tools/config-manager"
        "cache-analyzer" = "./tools/cache-analyzer"
    }
    
    foreach ($toolName in $tools.Keys) {
        $toolPackage = $tools[$toolName]
        if (Test-Path (Join-Path $PROJECT_ROOT $toolPackage.TrimStart('./'))) {
            Write-Status "Building tool: $toolName"
            foreach ($platform in $platformsToBuild) {
                $binaryName = "$toolName-$platform$($PLATFORMS[$platform].EXT)"
                $outputPath = Join-Path $OutputDir $binaryName
                
                $env:GOOS = $PLATFORMS[$platform].OS
                $env:GOARCH = $PLATFORMS[$platform].ARCH
                $env:CGO_ENABLED = "0"
                
                $buildArgs = @("build") + $BUILD_FLAGS + @("-o", $outputPath, $toolPackage)
                & go @buildArgs
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Built $toolName for $platform"
                }
            }
        }
    }
    
    # Copy configurations and create deployment files
    Copy-Configs
    Generate-DeploymentInfo
    
    # Create system service files
    if ($platformsToBuild -contains "linux") {
        Create-SystemdService
    }
    
    if ($platformsToBuild -contains "windows") {
        Create-WindowsService
    }
    
    # Create deployment documentation
    $deploymentDoc = @"
# Email Sender Native Deployment

## Built Version: $BUILD_VERSION
## Build Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Files Included:
$(Get-ChildItem $OutputDir | ForEach-Object { "- $($_.Name)" } | Out-String)

## Deployment Instructions:

### Linux Deployment:
1. Copy email-sender-linux to /opt/email-sender/
2. Copy configs/ to /opt/email-sender/configs/
3. Install systemd service: sudo cp email-sender.service /etc/systemd/system/
4. Enable and start: sudo systemctl enable --now email-sender

### Windows Deployment:
1. Copy email-sender-windows.exe to C:\Program Files\EmailSender\
2. Copy configs/ to C:\Program Files\EmailSender\configs\
3. Run install-windows-service.bat as Administrator

### Configuration:
- Edit configs/production.yaml for production settings
- Set environment variables as needed
- Configure monitoring endpoints

## Monitoring:
- Health check: http://localhost:8080/health
- Metrics: http://localhost:8080/metrics
- Dashboard: http://localhost:8080/monitoring

"@
    
    $deploymentDoc | Set-Content (Join-Path $OutputDir "DEPLOYMENT.md")
    
    Write-Host ""
    Write-Success "🎉 Production build completed successfully!"
    Write-Host "📦 Output directory: $OutputDir" -ForegroundColor Blue
    Write-Host "📋 See DEPLOYMENT.md for installation instructions" -ForegroundColor Blue
    
    if ($Deploy) {
        Write-Status "Initiating deployment process..."
        # Here you would add deployment logic
        Write-Host "⚠️  Deployment flag detected but deployment logic not implemented yet" -ForegroundColor Yellow
    }
}

# Run the main function
Main