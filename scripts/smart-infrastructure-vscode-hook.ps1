# 🚀 Smart Infrastructure VS Code Auto-Start Hook
# Automatically starts the smart infrastructure when VS Code opens the workspace

param(
   [string]$Action = "start",
   [string]$Profile = "development",
   [switch]$Background = $false,
   [switch]$Monitor = $false,
   [switch]$Verbose = $false
)

# Configuration
$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$SmartInfrastructureBinary = Join-Path $WorkspaceRoot "smart-infrastructure.exe"
$LogFile = Join-Path $WorkspaceRoot "logs" "smart-infrastructure-vscode.log"

# Ensure logs directory exists
$LogsDir = Split-Path -Parent $LogFile
if (-not (Test-Path $LogsDir)) {
   New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
}

# Logging function
function Write-Log {
   param([string]$Message, [string]$Level = "INFO")
   $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $LogMessage = "[$Timestamp] [$Level] $Message"
   Write-Host $LogMessage
   Add-Content -Path $LogFile -Value $LogMessage
}

# Check if smart infrastructure binary exists
function Test-SmartInfrastructure {
   if (-not (Test-Path $SmartInfrastructureBinary)) {
      Write-Log "Smart Infrastructure binary not found at: $SmartInfrastructureBinary" "ERROR"
      Write-Log "Building Smart Infrastructure..." "INFO"
        
      try {
         Push-Location $WorkspaceRoot
         & go build -o smart-infrastructure.exe ./cmd/smart-infrastructure/
         if ($LASTEXITCODE -ne 0) {
            throw "Build failed"
         }
         Write-Log "Smart Infrastructure built successfully" "SUCCESS"
      }
      catch {
         Write-Log "Failed to build Smart Infrastructure: $_" "ERROR"
         return $false
      }
      finally {
         Pop-Location
      }
   }
   return $true
}

# Check if Docker is available
function Test-DockerAvailability {
   try {
      & docker version | Out-Null
      if ($LASTEXITCODE -ne 0) {
         throw "Docker not available"
      }
      return $true
   }
   catch {
      Write-Log "Docker is not available or not running" "ERROR"
      Write-Log "Please start Docker and try again" "ERROR"
      return $false
   }
}

# Start Smart Infrastructure
function Start-SmartInfrastructure {
   Write-Log "🚀 Starting Smart Infrastructure with profile: $Profile" "INFO"
    
   # Set environment for the profile
   $env:DEPLOYMENT_PROFILE = $Profile
   $env:ENVIRONMENT = $Profile
    
   try {
      if ($Background) {
         # Start in background
         $ProcessInfo = Start-Process -FilePath $SmartInfrastructureBinary -ArgumentList $Action -NoNewWindow -PassThru
         Write-Log "Smart Infrastructure started in background (PID: $($ProcessInfo.Id))" "SUCCESS"
            
         # Save PID for later management
         $ProcessInfo.Id | Out-File -FilePath (Join-Path $WorkspaceRoot ".smart-infrastructure.pid") -Encoding UTF8
            
         if ($Monitor) {
            Start-MonitoringLoop
         }
      }
      else {
         # Start in foreground
         & $SmartInfrastructureBinary $Action
         if ($LASTEXITCODE -eq 0) {
            Write-Log "Smart Infrastructure completed successfully" "SUCCESS"
         }
         else {
            Write-Log "Smart Infrastructure exited with code: $LASTEXITCODE" "ERROR"
         }
      }
   }
   catch {
      Write-Log "Failed to start Smart Infrastructure: $_" "ERROR"
      return $false
   }
    
   return $true
}

# Monitor Smart Infrastructure status
function Start-MonitoringLoop {
   Write-Log "📡 Starting monitoring loop..." "INFO"
    
   while ($true) {
      Start-Sleep -Seconds 60
        
      try {
         & $SmartInfrastructureBinary "status" | Out-String | ForEach-Object {
            Write-Log $_.Trim() "MONITOR"
         }
      }
      catch {
         Write-Log "Monitoring check failed: $_" "WARNING"
      }
   }
}

# Stop Smart Infrastructure
function Stop-SmartInfrastructure {
   Write-Log "🛑 Stopping Smart Infrastructure..." "INFO"
    
   # Check for running process
   $PidFile = Join-Path $WorkspaceRoot ".smart-infrastructure.pid"
   if (Test-Path $PidFile) {
      try {
         $Pid = Get-Content $PidFile -ErrorAction Stop
         $Process = Get-Process -Id $Pid -ErrorAction Stop
            
         Write-Log "Stopping process (PID: $Pid)..." "INFO"
         $Process.Kill()
         $Process.WaitForExit(10000)  # Wait up to 10 seconds
            
         Remove-Item $PidFile -Force
         Write-Log "Smart Infrastructure stopped successfully" "SUCCESS"
      }
      catch {
         Write-Log "Could not stop process from PID file: $_" "WARNING"
      }
   }
    
   # Also try to stop via docker-compose
   try {
      Push-Location $WorkspaceRoot
      & $SmartInfrastructureBinary "stop"
      Write-Log "Services stopped via Smart Infrastructure" "SUCCESS"
   }
   catch {
      Write-Log "Failed to stop services: $_" "ERROR"
   }
   finally {
      Pop-Location
   }
}

# Get Smart Infrastructure status
function Get-SmartInfrastructureStatus {
   Write-Log "📊 Checking Smart Infrastructure status..." "INFO"
    
   try {
      & $SmartInfrastructureBinary "status"
      if ($LASTEXITCODE -eq 0) {
         Write-Log "Status check completed successfully" "SUCCESS"
      }
      else {
         Write-Log "Status check returned code: $LASTEXITCODE" "WARNING"
      }
   }
   catch {
      Write-Log "Failed to get status: $_" "ERROR"
   }
}

# Display Smart Infrastructure info
function Get-SmartInfrastructureInfo {
   Write-Log "ℹ️ Getting Smart Infrastructure information..." "INFO"
    
   try {
      & $SmartInfrastructureBinary "info"
      Write-Log "Info retrieved successfully" "SUCCESS"
   }
   catch {
      Write-Log "Failed to get info: $_" "ERROR"
   }
}

# Auto-detect VS Code workspace opening
function Initialize-VSCodeIntegration {
   Write-Log "🎮 Initializing VS Code Smart Infrastructure integration..." "INFO"
    
   # Check if we're in a VS Code integrated terminal
   $IsVSCodeTerminal = $env:TERM_PROGRAM -eq "vscode" -or $env:VSCODE_PID -ne $null
    
   if ($IsVSCodeTerminal) {
      Write-Log "VS Code detected, setting up automatic integration..." "INFO"
        
      # Auto-detect optimal profile based on workspace
      $DetectedProfile = "development"
      if (Test-Path (Join-Path $WorkspaceRoot "config/deploy-production.json")) {
         $DetectedProfile = "production"
      }
      elseif (Test-Path (Join-Path $WorkspaceRoot "config/deploy-staging.json")) {
         $DetectedProfile = "staging"
      }
        
      Write-Log "Auto-detected profile: $DetectedProfile" "INFO"
        
      # Override with environment variable if set
      if ($env:DEPLOYMENT_PROFILE) {
         $DetectedProfile = $env:DEPLOYMENT_PROFILE
         Write-Log "Using environment profile: $DetectedProfile" "INFO"
      }
        
      $Profile = $DetectedProfile
   }
}

# Main execution
function Main {
   Write-Log "🚀 Smart Infrastructure VS Code Hook - Action: $Action, Profile: $Profile" "INFO"
    
   # Initialize VS Code integration
   Initialize-VSCodeIntegration
    
   # Pre-flight checks
   if (-not (Test-DockerAvailability)) {
      exit 1
   }
    
   if (-not (Test-SmartInfrastructure)) {
      exit 1
   }
    
   # Execute requested action
   switch ($Action.ToLower()) {
      "start" {
         $success = Start-SmartInfrastructure
         if (-not $success) { exit 1 }
      }
      "stop" {
         Stop-SmartInfrastructure
      }
      "status" {
         Get-SmartInfrastructureStatus
      }
      "info" {
         Get-SmartInfrastructureInfo
      }
      "monitor" {
         if (Start-SmartInfrastructure) {
            Start-MonitoringLoop
         }
      }
      "auto" {
         # Auto mode: start if not running, otherwise show status
         Write-Log "Auto mode: checking current status..." "INFO"
            
         try {
            & $SmartInfrastructureBinary "status" | Out-Null
            if ($LASTEXITCODE -eq 0) {
               Write-Log "Services already running, showing status..." "INFO"
               Get-SmartInfrastructureStatus
            }
            else {
               Write-Log "Services not running, starting..." "INFO"
               $success = Start-SmartInfrastructure
               if (-not $success) { exit 1 }
            }
         }
         catch {
            Write-Log "Starting services..." "INFO"
            $success = Start-SmartInfrastructure
            if (-not $success) { exit 1 }
         }
      }
      default {
         Write-Log "Unknown action: $Action" "ERROR"
         Write-Host @"
Usage: smart-infrastructure-vscode-hook.ps1 [Action] [Options]

Actions:
  start     Start the Smart Infrastructure
  stop      Stop the Smart Infrastructure  
  status    Show current status
  info      Show environment information
  monitor   Start with continuous monitoring
  auto      Auto-detect and start if needed (default for VS Code)

Options:
  -Profile <profile>    Set deployment profile (development|staging|production)
  -Background          Run in background
  -Monitor             Enable continuous monitoring
  -Verbose             Enable verbose logging

Examples:
  .\smart-infrastructure-vscode-hook.ps1 start -Profile development
  .\smart-infrastructure-vscode-hook.ps1 auto -Background -Monitor
  .\smart-infrastructure-vscode-hook.ps1 status
"@
         exit 1
      }
   }
    
   Write-Log "Smart Infrastructure VS Code Hook completed" "SUCCESS"
}

# Execute main function
Main
