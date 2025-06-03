# Enhanced Monitoring and Alerting System - Plan Dev v41
# Phase 1.1.1.4 - System de surveillance et d'alerte avance
# Version: 1.0
# Date: 2025-06-03

[CmdletBinding()]
param(
   [Parameter(HelpMessage = "Mode de surveillance")]
   [ValidateSet("Start", "Stop", "Status", "Alert", "Report")]
   [string]$Mode = "Start",
    
   [Parameter(HelpMessage = "Intervalle de surveillance en secondes")]
   [int]$IntervalSeconds = 30,
    
   [Parameter(HelpMessage = "Activer les alertes en temps reel")]
   [switch]$EnableRealTimeAlerts,
    
   [Parameter(HelpMessage = "Seuil d'alerte pour l'utilisation disque (%)")]
   [int]$DiskUsageThreshold = 85,
    
   [Parameter(HelpMessage = "Seuil d'alerte pour la memoire (%)")]
   [int]$MemoryThreshold = 80,
    
   [Parameter(HelpMessage = "Generer un rapport detaille")]
   [switch]$GenerateReport
)

# ===== CONFIGURATION GLOBALE =====

$Global:MonitoringConfig = @{
   ProjectRoot     = Get-Location
   LogPath         = ".\projet\security\logs\monitoring.log"
   AlertsPath      = ".\projet\security\logs\alerts.log"
   ReportsPath     = ".\projet\security\reports"
   StatusFile      = ".\projet\security\logs\monitoring-status.json"
   ConfigFile      = ".\projet\security\monitoring-config.json"
   IntervalSeconds = $IntervalSeconds
   Thresholds      = @{
      DiskUsage     = $DiskUsageThreshold
      Memory        = $MemoryThreshold
      FileCount     = 1000
      DirectorySize = 500MB
   }
   AlertLevels     = @{
      Info      = 1
      Warning   = 2
      Critical  = 3
      Emergency = 4
   }
}

# ===== FONCTIONS UTILITAIRES =====

function Write-MonitoringLog {
   param(
      [string]$Message,
      [ValidateSet("Info", "Warning", "Critical", "Emergency")]
      [string]$Level = "Info",
      [string]$Component = "Monitor"
   )
    
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $logEntry = "[$timestamp] [$Level] [$Component] $Message"
    
   $color = switch ($Level) {
      "Info" { "White" }
      "Warning" { "Yellow" }
      "Critical" { "Red" }
      "Emergency" { "Magenta" }
   }
    
   Write-Host $logEntry -ForegroundColor $color
    
   # Ecrire dans le fichier de log
   try {
      Add-Content -Path $MonitoringConfig.LogPath -Value $logEntry -ErrorAction SilentlyContinue
   }
   catch {
      # Silently fail if can't write to log
   }
    
   # Ecrire les alertes dans un fichier separe
   if ($Level -in @("Warning", "Critical", "Emergency")) {
      try {
         Add-Content -Path $MonitoringConfig.AlertsPath -Value $logEntry -ErrorAction SilentlyContinue
      }
      catch {
         # Silently fail if can't write to alerts
      }
   }
}

function Initialize-MonitoringSystem {
   Write-MonitoringLog "Initialisation du systeme de surveillance" -Level "Info"
    
   # Creer les repertoires necessaires
   $directories = @(
      "projet\security\logs",
      "projet\security\reports",
      "projet\security\alerts"
   )
    
   foreach ($dir in $directories) {
      $fullPath = Join-Path $MonitoringConfig.ProjectRoot $dir
      if (-not (Test-Path $fullPath)) {
         New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
      }
   }
    
   # Creer le fichier de configuration par defaut
   if (-not (Test-Path $MonitoringConfig.ConfigFile)) {
      $defaultConfig = @{
         Version            = "1.0"
         Enabled            = $true
         Interval           = $MonitoringConfig.IntervalSeconds
         Thresholds         = $MonitoringConfig.Thresholds
         WatchedDirectories = @(
            ".",
            ".\tools",
            ".\projet"
         )
         CriticalFiles      = @(
            "go.mod",
            "go.sum",
            "package.json",
            ".gitmodules",
            "organize-root-files-secure.ps1"
         )
         ExcludePatterns    = @(
            "*.exe",
            "*.log",
            ".git\*",
            "node_modules\*"
         )
      }
        
      $defaultConfig | ConvertTo-Json -Depth 5 | Out-File -FilePath $MonitoringConfig.ConfigFile -Encoding utf8
      Write-MonitoringLog "Fichier de configuration cree: $($MonitoringConfig.ConfigFile)" -Level "Info"
   }
    
   Write-MonitoringLog "Systeme de surveillance initialise" -Level "Info"
}

# ===== FONCTIONS DE SURVEILLANCE =====

function Get-SystemMetrics {
   try {
      $metrics = @{
         Timestamp = Get-Date
         CPU       = @{
            Usage = (Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
         }
         Memory    = @{
            Total     = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory
            Available = (Get-WmiObject -Class Win32_OperatingSystem).FreePhysicalMemory * 1KB
            Usage     = 0
         }
         Disk      = @{
            Total = 0
            Free  = 0
            Usage = 0
         }
      }
        
      # Calculer l'utilisation memoire
      $metrics.Memory.Usage = [math]::Round((($metrics.Memory.Total - $metrics.Memory.Available) / $metrics.Memory.Total) * 100, 2)
        
      # Obtenir les informations disque pour le lecteur principal
      $drive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
      if ($drive) {
         $metrics.Disk.Total = $drive.Size
         $metrics.Disk.Free = $drive.FreeSpace
         $metrics.Disk.Usage = [math]::Round((($drive.Size - $drive.FreeSpace) / $drive.Size) * 100, 2)
      }
        
      return $metrics
   }
   catch {
      Write-MonitoringLog "Erreur lors de la collecte des metriques systeme: $_" -Level "Warning"
      return $null
   }
}

function Get-ProjectMetrics {
   try {
      $config = Get-Content $MonitoringConfig.ConfigFile | ConvertFrom-Json
        
      $metrics = @{
         Timestamp   = Get-Date
         Files       = @{
            Total            = 0
            CriticalFiles    = @()
            ModifiedRecently = @()
         }
         Directories = @{
            Total = 0
            Sizes = @{}
         }
         Security    = @{
            IntegrityChecks = @()
            Violations      = @()
         }
      }
        
      # Analyser les fichiers critiques
      foreach ($file in $config.CriticalFiles) {
         $filePath = Join-Path $MonitoringConfig.ProjectRoot $file
         if (Test-Path $filePath) {
            $fileInfo = Get-Item $filePath
            $metrics.Files.CriticalFiles += @{
               Path         = $filePath
               Size         = $fileInfo.Length
               LastModified = $fileInfo.LastWriteTime
               Hash         = (Get-FileHash $filePath -Algorithm SHA256).Hash
            }
                
            # Verifier si modifie recemment (derniere heure)
            if ($fileInfo.LastWriteTime -gt (Get-Date).AddHours(-1)) {
               $metrics.Files.ModifiedRecently += $filePath
            }
         }
      }
        
      # Analyser les repertoires surveilles
      foreach ($dir in $config.WatchedDirectories) {
         $dirPath = Join-Path $MonitoringConfig.ProjectRoot $dir
         if (Test-Path $dirPath) {
            $dirSize = (Get-ChildItem -Path $dirPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            $metrics.Directories.Sizes[$dir] = $dirSize
            $metrics.Directories.Total++
                
            # Verifier le seuil de taille
            if ($dirSize -gt $MonitoringConfig.Thresholds.DirectorySize) {
               $metrics.Security.Violations += "Repertoire $dir depasse le seuil de taille ($([math]::Round($dirSize / 1MB, 2)) MB)"
            }
         }
      }
        
      return $metrics
   }
   catch {
      Write-MonitoringLog "Erreur lors de la collecte des metriques projet: $_" -Level "Warning"
      return $null
   }
}

function Test-SecurityCompliance {
   try {
      $violations = @()
        
      # Verifier l'existence du script securise
      if (-not (Test-Path ".\organize-root-files-secure.ps1")) {
         $violations += "Script securise manquant: organize-root-files-secure.ps1"
      }
        
      # Verifier la configuration de protection
      if (-not (Test-Path ".\projet\security\protection-config.json")) {
         $violations += "Configuration de protection manquante"
      }
        
      # Verifier les outils de securite
      $securityTools = @(
         ".\tools\security\script-analyzer-v2.ps1",
         ".\tools\security\real-time-validator.ps1"
      )
        
      foreach ($tool in $securityTools) {
         if (-not (Test-Path $tool)) {
            $violations += "Outil de securite manquant: $tool"
         }
      }
        
      # Verifier les permissions des fichiers critiques (simulation)
      $criticalFiles = @("go.mod", "package.json", ".gitmodules")
      foreach ($file in $criticalFiles) {
         if (Test-Path $file) {
            # En production, on verifierait les permissions reelles
            # Pour l'instant, on simule une verification
         }
      }
        
      return $violations
   }
   catch {
      Write-MonitoringLog "Erreur lors de la verification de conformite: $_" -Level "Warning"
      return @("Erreur lors de la verification de conformite")
   }
}

function Invoke-AlertCheck {
   param(
      [hashtable]$SystemMetrics,
      [hashtable]$ProjectMetrics
   )
    
   $alerts = @()
    
   # Verifier les seuils systeme
   if ($SystemMetrics -and $SystemMetrics.Memory.Usage -gt $MonitoringConfig.Thresholds.Memory) {
      $alerts += @{
         Level     = "Warning"
         Component = "System"
         Message   = "Utilisation memoire elevee: $($SystemMetrics.Memory.Usage)%"
         Timestamp = Get-Date
      }
   }
    
   if ($SystemMetrics -and $SystemMetrics.Disk.Usage -gt $MonitoringConfig.Thresholds.DiskUsage) {
      $alerts += @{
         Level     = "Critical"
         Component = "System"
         Message   = "Utilisation disque critique: $($SystemMetrics.Disk.Usage)%"
         Timestamp = Get-Date
      }
   }
    
   # Verifier les modifications de fichiers critiques
   if ($ProjectMetrics -and $ProjectMetrics.Files.ModifiedRecently.Count -gt 0) {
      $alerts += @{
         Level     = "Warning"
         Component = "Security"
         Message   = "Fichiers critiques modifies: $($ProjectMetrics.Files.ModifiedRecently -join ', ')"
         Timestamp = Get-Date
      }
   }
    
   # Verifier les violations de securite
   $violations = Test-SecurityCompliance
   foreach ($violation in $violations) {
      $alerts += @{
         Level     = "Critical"
         Component = "Security"
         Message   = $violation
         Timestamp = Get-Date
      }
   }
    
   # Traiter les alertes
   foreach ($alert in $alerts) {
      Write-MonitoringLog $alert.Message -Level $alert.Level -Component $alert.Component
        
      if ($EnableRealTimeAlerts -and $alert.Level -in @("Critical", "Emergency")) {
         # En production, on pourrait envoyer des notifications (email, SMS, etc.)
         Write-Host "ALERTE CRITIQUE: $($alert.Message)" -ForegroundColor Red -BackgroundColor Yellow
      }
   }
    
   return $alerts
}

function Save-MonitoringStatus {
   param(
      [hashtable]$SystemMetrics,
      [hashtable]$ProjectMetrics,
      [array]$Alerts
   )
    
   $status = @{
      Timestamp      = Get-Date
      Status         = "Running"
      SystemMetrics  = $SystemMetrics
      ProjectMetrics = $ProjectMetrics
      Alerts         = $Alerts
      AlertCount     = $Alerts.Count
      CriticalAlerts = ($Alerts | Where-Object { $_.Level -in @("Critical", "Emergency") }).Count
   }
    
   try {
      $status | ConvertTo-Json -Depth 5 | Out-File -FilePath $MonitoringConfig.StatusFile -Encoding utf8
   }
   catch {
      Write-MonitoringLog "Impossible de sauvegarder le statut: $_" -Level "Warning"
   }
}

# ===== FONCTIONS PRINCIPALES =====

function Start-ContinuousMonitoring {
   Write-MonitoringLog "Demarrage de la surveillance continue" -Level "Info"
    
   $iteration = 0
   while ($true) {
      try {
         $iteration++
         Write-MonitoringLog "Cycle de surveillance #$iteration" -Level "Info"
            
         # Collecter les metriques
         $systemMetrics = Get-SystemMetrics
         $projectMetrics = Get-ProjectMetrics
            
         # Verifier les alertes
         $alerts = Invoke-AlertCheck -SystemMetrics $systemMetrics -ProjectMetrics $projectMetrics
            
         # Sauvegarder le statut
         Save-MonitoringStatus -SystemMetrics $systemMetrics -ProjectMetrics $projectMetrics -Alerts $alerts
            
         # Afficher un resume
         if ($systemMetrics) {
            Write-MonitoringLog "CPU: $($systemMetrics.CPU.Usage)% | RAM: $($systemMetrics.Memory.Usage)% | Disque: $($systemMetrics.Disk.Usage)%" -Level "Info"
         }
            
         if ($alerts.Count -gt 0) {
            Write-MonitoringLog "$($alerts.Count) alerte(s) detectee(s)" -Level "Warning"
         }
            
         # Attendre avant le prochain cycle
         Start-Sleep -Seconds $MonitoringConfig.IntervalSeconds
      }
      catch {
         Write-MonitoringLog "Erreur dans le cycle de surveillance: $_" -Level "Critical"
         Start-Sleep -Seconds 10  # Attente plus courte en cas d'erreur
      }
   }
}

function Get-MonitoringStatus {
   if (Test-Path $MonitoringConfig.StatusFile) {
      try {
         $status = Get-Content $MonitoringConfig.StatusFile | ConvertFrom-Json
            
         Write-Host "`nStatut du systeme de surveillance:" -ForegroundColor Cyan
         Write-Host "=================================" -ForegroundColor Cyan
         Write-Host "Statut: $($status.Status)" -ForegroundColor $(if ($status.Status -eq "Running") { "Green" } else { "Red" })
         Write-Host "Derniere mise a jour: $($status.Timestamp)" -ForegroundColor Gray
            
         if ($status.SystemMetrics) {
            Write-Host "`nMetriques systeme:" -ForegroundColor White
            Write-Host "  CPU: $($status.SystemMetrics.CPU.Usage)%" -ForegroundColor White
            Write-Host "  Memoire: $($status.SystemMetrics.Memory.Usage)%" -ForegroundColor $(if ($status.SystemMetrics.Memory.Usage -gt 80) { "Red" } else { "Green" })
            Write-Host "  Disque: $($status.SystemMetrics.Disk.Usage)%" -ForegroundColor $(if ($status.SystemMetrics.Disk.Usage -gt 85) { "Red" } else { "Green" })
         }
            
         Write-Host "`nAlertes:" -ForegroundColor White
         Write-Host "  Total: $($status.AlertCount)" -ForegroundColor White
         Write-Host "  Critiques: $($status.CriticalAlerts)" -ForegroundColor $(if ($status.CriticalAlerts -gt 0) { "Red" } else { "Green" })
            
         return $true
      }
      catch {
         Write-MonitoringLog "Erreur lors de la lecture du statut: $_" -Level "Warning"
         return $false
      }
   }
   else {
      Write-Host "Aucun fichier de statut trouve. Le systeme de surveillance n'est pas actif." -ForegroundColor Yellow
      return $false
   }
}

function Start-MonitoringSystem {
   try {
      Initialize-MonitoringSystem
        
      switch ($Mode) {
         "Start" {
            Write-Host "Demarrage du systeme de surveillance..." -ForegroundColor Green
            Write-Host "Appuyez sur Ctrl+C pour arreter" -ForegroundColor Yellow
            Start-ContinuousMonitoring
         }
            
         "Status" {
            Get-MonitoringStatus
         }
            
         "Alert" {
            # Test manuel des alertes
            Write-MonitoringLog "Test manuel des alertes" -Level "Info"
            $systemMetrics = Get-SystemMetrics
            $projectMetrics = Get-ProjectMetrics
            $alerts = Invoke-AlertCheck -SystemMetrics $systemMetrics -ProjectMetrics $projectMetrics
                
            if ($alerts.Count -eq 0) {
               Write-Host "Aucune alerte detectee" -ForegroundColor Green
            }
            else {
               Write-Host "$($alerts.Count) alerte(s) detectee(s)" -ForegroundColor Red
            }
         }
            
         "Report" {
            if ($GenerateReport) {
               # Generer un rapport detaille (a implementer)
               Write-Host "Generation de rapport non implementee dans cette version" -ForegroundColor Yellow
            }
         }
            
         default {
            Write-Host "Mode invalide. Utilisez: Start, Status, Alert, Report" -ForegroundColor Red
            return 1
         }
      }
        
      return 0
   }
   catch {
      Write-MonitoringLog "Erreur critique: $_" -Level "Emergency"
      return 1
   }
}

# ===== POINT D'ENTREE =====

$ErrorActionPreference = "Continue"
$InformationPreference = "Continue"

exit (Start-MonitoringSystem)
