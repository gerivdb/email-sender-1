# Planning Ecosystem Sync - Administration Script
# Purpose: Provide administrative functions for the sync ecosystem

param(
   [Parameter(Mandatory = $false)]
   [ValidateSet("init", "validate", "sync", "status", "cleanup", "backup", "restore")]
   [string]$Action = "status",
    
   [Parameter(Mandatory = $false)]
   [string]$ConfigPath = ".\config\sync-config.yaml",
    
   [Parameter(Mandatory = $false)]
   [string]$PlanPath = ".\projet\roadmaps\plans\",
    
   [Parameter(Mandatory = $false)]
   [switch]$Verbose,
    
   [Parameter(Mandatory = $false)]
   [switch]$Force
)

# Configuration and logging setup
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogFile = Join-Path $ScriptDir "admin.log"

function Write-Log {
   param(
      [string]$Message,
      [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
      [string]$Level = "INFO"
   )
    
   $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $LogEntry = "[$Timestamp] [$Level] $Message"
    
   # Write to console with color coding
   switch ($Level) {
      "INFO" { Write-Host $LogEntry -ForegroundColor Green }
      "WARNING" { Write-Host $LogEntry -ForegroundColor Yellow }
      "ERROR" { Write-Host $LogEntry -ForegroundColor Red }
      "DEBUG" { if ($Verbose) { Write-Host $LogEntry -ForegroundColor Cyan } }
   }
    
   # Write to log file
   Add-Content -Path $LogFile -Value $LogEntry
}

function Test-Prerequisites {
   Write-Log "🔍 Checking prerequisites..." -Level "INFO"
    
   $Prerequisites = @(
      @{ Name = "Go"; Command = "go version"; Required = $true },
      @{ Name = "Git"; Command = "git --version"; Required = $true },
      @{ Name = "PowerShell"; Command = "pwsh --version"; Required = $true },
      @{ Name = "QDrant"; Command = "curl -s http://localhost:6333/"; Required = $false },
      @{ Name = "PostgreSQL"; Command = "psql --version"; Required = $false }
   )
    
   $AllGood = $true
    
   foreach ($Prereq in $Prerequisites) {
      try {
         $null = Invoke-Expression $Prereq.Command -ErrorAction Stop
         Write-Log "✅ $($Prereq.Name) is available" -Level "INFO"
      }
      catch {
         if ($Prereq.Required) {
            Write-Log "❌ $($Prereq.Name) is required but not available" -Level "ERROR"
            $AllGood = $false
         }
         else {
            Write-Log "⚠️  $($Prereq.Name) is optional but not available" -Level "WARNING"
         }
      }
   }
    
   return $AllGood
}

function Initialize-Environment {
   Write-Log "🚀 Initializing Planning Ecosystem Sync environment..." -Level "INFO"
    
   # Create directory structure if it doesn't exist
   $Directories = @(
      "planning-ecosystem-sync\docs",
      "planning-ecosystem-sync\tools\sync-core",
      "planning-ecosystem-sync\tools\task-manager",
      "planning-ecosystem-sync\tools\config-validator",
      "planning-ecosystem-sync\tools\migration-assistant",
      "planning-ecosystem-sync\config\sync-mappings",
      "planning-ecosystem-sync\config\validation-rules",
      "planning-ecosystem-sync\config\templates",
      "planning-ecosystem-sync\scripts\powershell",
      "planning-ecosystem-sync\scripts\automation",
      "planning-ecosystem-sync\tests\unit",
      "planning-ecosystem-sync\tests\integration",
      "planning-ecosystem-sync\tests\performance",
      "planning-ecosystem-sync\web\dashboard",
      "planning-ecosystem-sync\web\api",
      "planning-ecosystem-sync\docs\user-guides",
      "planning-ecosystem-sync\docs\technical",
      "planning-ecosystem-sync\docs\api-reference"
   )
    
   foreach ($Dir in $Directories) {
      if (-not (Test-Path $Dir)) {
         New-Item -ItemType Directory -Path $Dir -Force | Out-Null
         Write-Log "📁 Created directory: $Dir" -Level "INFO"
      }
      else {
         Write-Log "📁 Directory exists: $Dir" -Level "DEBUG"
      }
   }
    
   # Initialize Go modules
   $GoModules = @(
      "planning-ecosystem-sync\tools\sync-core",
      "planning-ecosystem-sync\tools\task-manager",
      "planning-ecosystem-sync\tools\config-validator",
      "planning-ecosystem-sync\tools\migration-assistant"
   )
    
   foreach ($Module in $GoModules) {
      $GoModFile = Join-Path $Module "go.mod"
      if (-not (Test-Path $GoModFile)) {
         Set-Location $Module
         $ModuleName = "github.com/planning-ecosystem/$(Split-Path $Module -Leaf)"
         go mod init $ModuleName
         Write-Log "🔧 Initialized Go module: $ModuleName" -Level "INFO"
         Set-Location $ScriptDir
      }
   }
    
   Write-Log "✅ Environment initialization complete" -Level "INFO"
}

function Test-Configuration {
   Write-Log "🔍 Validating configuration..." -Level "INFO"
    
   if (-not (Test-Path $ConfigPath)) {
      Write-Log "❌ Configuration file not found: $ConfigPath" -Level "ERROR"
      return $false
   }
    
   try {
      # Basic YAML validation (simplified)
      $ConfigContent = Get-Content $ConfigPath -Raw
        
      # Check for required sections
      $RequiredSections = @("ecosystem", "storage", "synchronization")
      foreach ($Section in $RequiredSections) {
         if ($ConfigContent -notmatch "$Section:") {
            Write-Log "❌ Missing required section: $Section" -Level "ERROR"
            return $false
         }
      }
        
      Write-Log "✅ Configuration validation passed" -Level "INFO"
      return $true
   }
   catch {
      Write-Log "❌ Configuration validation failed: $($_.Exception.Message)" -Level "ERROR"
      return $false
   }
}

function Get-SyncStatus {
   Write-Log "📊 Getting synchronization status..." -Level "INFO"
    
   # Check Git branch
   try {
      $CurrentBranch = git branch --show-current
      Write-Log "🌿 Current Git branch: $CurrentBranch" -Level "INFO"
        
      if ($CurrentBranch -ne "planning-ecosystem-sync") {
         Write-Log "⚠️  Not on planning-ecosystem-sync branch" -Level "WARNING"
      }
   }
   catch {
      Write-Log "❌ Failed to get Git branch: $($_.Exception.Message)" -Level "ERROR"
   }
    
   # Check for uncommitted changes
   try {
      $GitStatus = git status --porcelain
      if ($GitStatus) {
         Write-Log "📝 Uncommitted changes detected:" -Level "INFO"
         $GitStatus | ForEach-Object { Write-Log "   $_" -Level "INFO" }
      }
      else {
         Write-Log "✅ Working directory clean" -Level "INFO"
      }
   }
   catch {
      Write-Log "❌ Failed to get Git status: $($_.Exception.Message)" -Level "ERROR"
   }
    
   # Check plan files
   if (Test-Path $PlanPath) {
      $PlanFiles = Get-ChildItem -Path $PlanPath -Filter "*.md" -Recurse
      Write-Log "📄 Found $($PlanFiles.Count) Markdown plan files" -Level "INFO"
   }
   else {
      Write-Log "⚠️  Plan directory not found: $PlanPath" -Level "WARNING"
   }
}

function Invoke-Cleanup {
   Write-Log "🧹 Performing cleanup..." -Level "INFO"
    
   # Clean up temporary files
   $TempPatterns = @("*.tmp", "*.log.old", "*~", ".DS_Store")
    
   foreach ($Pattern in $TempPatterns) {
      $Files = Get-ChildItem -Path "." -Filter $Pattern -Recurse -ErrorAction SilentlyContinue
      foreach ($File in $Files) {
         Remove-Item $File.FullName -Force
         Write-Log "🗑️  Removed: $($File.FullName)" -Level "DEBUG"
      }
   }
    
   Write-Log "✅ Cleanup complete" -Level "INFO"
}

function New-Backup {
   param([string]$BackupPath = "backups\$(Get-Date -Format 'yyyyMMdd_HHmmss')")
    
   Write-Log "💾 Creating backup to: $BackupPath" -Level "INFO"
    
   if (-not (Test-Path "backups")) {
      New-Item -ItemType Directory -Path "backups" -Force | Out-Null
   }
    
   # Copy important files
   $SourcePaths = @(
      "planning-ecosystem-sync",
      "projet\roadmaps\plans",
      ".github\prompts\planning"
   )
    
   foreach ($Source in $SourcePaths) {
      if (Test-Path $Source) {
         $DestPath = Join-Path $BackupPath (Split-Path $Source -Leaf)
         Copy-Item -Path $Source -Destination $DestPath -Recurse -Force
         Write-Log "📋 Copied: $Source → $DestPath" -Level "INFO"
      }
   }
    
   Write-Log "✅ Backup created successfully" -Level "INFO"
}

# Main execution logic
Write-Log "🎯 Planning Ecosystem Sync Administration Tool" -Level "INFO"
Write-Log "Action: $Action" -Level "INFO"

switch ($Action) {
   "init" {
      if (Test-Prerequisites) {
         Initialize-Environment
      }
      else {
         Write-Log "❌ Prerequisites not met. Please install required tools." -Level "ERROR"
         exit 1
      }
   }
    
   "validate" {
      if (-not (Test-Configuration)) {
         exit 1
      }
   }
    
   "status" {
      Get-SyncStatus
   }
    
   "cleanup" {
      Invoke-Cleanup
   }
    
   "backup" {
      New-Backup
   }
    
   default {
      Write-Log "📋 Available actions: init, validate, sync, status, cleanup, backup, restore" -Level "INFO"
   }
}

Write-Log "🏁 Administration task completed" -Level "INFO"
