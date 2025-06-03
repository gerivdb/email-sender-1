# Simple Backup System - Plan Dev v41 Phase 1.1.1.3
# Version: 1.0 - Simplified
# Date: 2025-06-03

param(
   [string]$Mode = "CreateBackup",
   [string]$SessionId = "",
   [switch]$Force
)

$Global:BackupConfig = @{
   ProjectRoot   = Get-Location
   BackupPath    = ".\projet\security\backups"
   CriticalFiles = @(
      "go.mod",
      "go.sum",
      "package.json",
      ".gitmodules",
      "Dockerfile",
      "docker-compose.yml",
      "Makefile",
      "README.md"
   )
}

function Write-BackupLog {
   param([string]$Message, [string]$Level = "Info")
    
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $color = switch ($Level) {
      "Error" { "Red" }
      "Warning" { "Yellow" }
      "Success" { "Green" }
      default { "White" }
   }
   Write-Host "[$timestamp] $Message" -ForegroundColor $color
}

function Initialize-BackupSystem {
   Write-BackupLog "Initializing backup system" -Level "Info"
    
   if (-not (Test-Path $BackupConfig.BackupPath)) {
      New-Item -ItemType Directory -Path $BackupConfig.BackupPath -Force | Out-Null
      Write-BackupLog "Backup directory created: $($BackupConfig.BackupPath)" -Level "Success"
   }
    
   $subDirs = @("sessions", "critical")
   foreach ($dir in $subDirs) {
      $fullPath = Join-Path $BackupConfig.BackupPath $dir
      if (-not (Test-Path $fullPath)) {
         New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
      }
   }
}

function New-BackupSession {
   $sessionId = [Guid]::NewGuid().ToString()
   $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
   $sessionPath = Join-Path $BackupConfig.BackupPath "sessions\$timestamp-$sessionId"
    
   Write-BackupLog "Creating backup session: $sessionId" -Level "Info"
    
   try {
      New-Item -ItemType Directory -Path $sessionPath -Force | Out-Null
        
      $metadata = @{
         SessionId   = $sessionId
         Timestamp   = Get-Date
         ProjectRoot = $BackupConfig.ProjectRoot.Path
         BackupPath  = $sessionPath
         Files       = @()
      }
        
      $criticalBackupPath = Join-Path $sessionPath "critical"
      New-Item -ItemType Directory -Path $criticalBackupPath -Force | Out-Null
        
      $fileCount = 0
      foreach ($file in $BackupConfig.CriticalFiles) {
         $sourcePath = Join-Path $BackupConfig.ProjectRoot $file
         if (Test-Path $sourcePath) {
            $destinationPath = Join-Path $criticalBackupPath $file
            Copy-Item -Path $sourcePath -Destination $destinationPath -Force
                
            $metadata.Files += @{
               SourcePath = $sourcePath
               BackupPath = $destinationPath
               Size       = (Get-Item $sourcePath).Length
            }
                
            $fileCount++
            Write-BackupLog "Backed up: $file" -Level "Success"
         }
      }
        
      $metadataPath = Join-Path $sessionPath "metadata.json"
      $metadata | ConvertTo-Json -Depth 5 | Out-File -FilePath $metadataPath -Encoding utf8
        
      Write-BackupLog "Backup session created successfully: $sessionId" -Level "Success"
      Write-BackupLog "Files backed up: $fileCount" -Level "Info"
        
      return $sessionId
   }
   catch {
      Write-BackupLog "Error creating backup: $_" -Level "Error"
      throw
   }
}

function Get-BackupSessions {
   $sessionsPath = Join-Path $BackupConfig.BackupPath "sessions"
   if (-not (Test-Path $sessionsPath)) {
      return @()
   }
    
   $sessions = @()
   $sessionDirs = Get-ChildItem -Path $sessionsPath -Directory | Sort-Object Name -Descending
    
   foreach ($dir in $sessionDirs) {
      $metadataPath = Join-Path $dir.FullName "metadata.json"
      if (Test-Path $metadataPath) {
         try {
            $metadata = Get-Content $metadataPath | ConvertFrom-Json
            $sessions += $metadata
         }
         catch {
            Write-BackupLog "Error reading metadata for: $($dir.Name)" -Level "Warning"
         }
      }
   }
    
   return $sessions
}

function Show-BackupSessions {
   $sessions = Get-BackupSessions
    
   if ($sessions.Count -eq 0) {
      Write-Host "No backup sessions available." -ForegroundColor Yellow
      return
   }
    
   Write-Host "`nAvailable Backup Sessions:" -ForegroundColor Cyan
   Write-Host "=" * 50 -ForegroundColor Cyan
    
   $counter = 1
   foreach ($session in $sessions) {
      $timestamp = ([DateTime]$session.Timestamp).ToString("yyyy-MM-dd HH:mm:ss")
        
      Write-Host "`n$counter. Session: $($session.SessionId)" -ForegroundColor White
      Write-Host "   Date: $timestamp" -ForegroundColor Gray
      Write-Host "   Files: $($session.Files.Count)" -ForegroundColor Gray
        
      $counter++
   }
}

function Start-BackupSystem {
   try {
      Initialize-BackupSystem
        
      switch ($Mode) {
         "CreateBackup" {
            $sessionId = New-BackupSession
            Write-Host "`nBackup created successfully!" -ForegroundColor Green
            Write-Host "Session ID: $sessionId" -ForegroundColor Cyan
         }
            
         "ListBackups" {
            Show-BackupSessions
         }
            
         default {
            Write-Host "Invalid mode. Use: CreateBackup, ListBackups" -ForegroundColor Red
            return 1
         }
      }
        
      return 0
   }
   catch {
      Write-BackupLog "Critical error: $_" -Level "Error"
      return 1
   }
}

exit (Start-BackupSystem)
