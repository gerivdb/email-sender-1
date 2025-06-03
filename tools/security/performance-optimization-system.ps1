# Performance Optimization and Resource Management - Plan Dev v41
# Phase 1.1.1.5 - Optimisation des performances et gestion des ressources
# Version: 1.0
# Date: 2025-06-03

[CmdletBinding()]
param(
   [Parameter(HelpMessage = "Mode d'optimisation")]
   [ValidateSet("Analyze", "Optimize", "Monitor", "Report", "Clean")]
   [string]$Mode = "Analyze",
    
   [Parameter(HelpMessage = "Activer l'optimisation automatique")]
   [switch]$AutoOptimize,
    
   [Parameter(HelpMessage = "Seuil d'utilisation memoire pour optimisation (%)")]
   [int]$MemoryThreshold = 75,
    
   [Parameter(HelpMessage = "Taille maximale des fichiers de log (MB)")]
   [int]$MaxLogSizeMB = 50,
    
   [Parameter(HelpMessage = "Nombre de jours pour conserver les logs")]
   [int]$LogRetentionDays = 30,
    
   [Parameter(HelpMessage = "Generer un rapport de performance")]
   [switch]$GenerateReport
)

# ===== CONFIGURATION GLOBALE =====

$Global:OptimizationConfig = @{
   ProjectRoot       = Get-Location
   LogsPath          = ".\projet\security\logs"
   TempPath          = ".\projet\security\temp"
   ReportsPath       = ".\projet\security\reports"
   CachePath         = ".\projet\security\cache"
   PerformanceFile   = ".\projet\security\performance-metrics.json"
   OptimizationRules = @{
      MaxFileSize      = 100MB
      MaxDirectorySize = 500MB
      MaxLogFiles      = 50
      MaxTempFiles     = 100
      MemoryThreshold  = $MemoryThreshold
      CPUThreshold     = 80
   }
   CleanupPatterns   = @(
      "*.tmp",
      "*.log.old",
      "*.bak",
      "*.cache",
      "*~",
      "Thumbs.db"
   )
}

# ===== FONCTIONS UTILITAIRES =====

function Write-PerformanceLog {
   param(
      [string]$Message,
      [ValidateSet("Info", "Warning", "Success", "Error")]
      [string]$Level = "Info",
      [string]$Component = "Performance"
   )
    
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $color = switch ($Level) {
      "Info" { "White" }
      "Warning" { "Yellow" }
      "Success" { "Green" }
      "Error" { "Red" }
   }
    
   Write-Host "[$timestamp] [$Component] $Message" -ForegroundColor $color
}

function Initialize-PerformanceSystem {
   Write-PerformanceLog "Initialisation du systeme d'optimisation des performances" -Level "Info"
    
   $directories = @(
      $OptimizationConfig.LogsPath,
      $OptimizationConfig.TempPath,
      $OptimizationConfig.ReportsPath,
      $OptimizationConfig.CachePath
   )
    
   foreach ($dir in $directories) {
      if (-not (Test-Path $dir)) {
         New-Item -ItemType Directory -Path $dir -Force | Out-Null
         Write-PerformanceLog "Repertoire cree: $dir" -Level "Success"
      }
   }
}

function Get-PerformanceMetrics {
   Write-PerformanceLog "Collecte des metriques de performance" -Level "Info"
    
   try {
      # Metriques systeme (Compatible PowerShell 7+)
      $cpu = Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average
      $memory = Get-CimInstance -ClassName Win32_OperatingSystem
      $disk = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
        
      # Metriques projet
      $projectSize = 0
      $fileCount = 0
      $directoryCount = 0
        
      if (Test-Path $OptimizationConfig.ProjectRoot) {
         $files = Get-ChildItem -Path $OptimizationConfig.ProjectRoot -Recurse -File -ErrorAction SilentlyContinue
         $directories = Get-ChildItem -Path $OptimizationConfig.ProjectRoot -Recurse -Directory -ErrorAction SilentlyContinue
            
         $projectSize = ($files | Measure-Object -Property Length -Sum).Sum
         $fileCount = $files.Count
         $directoryCount = $directories.Count
      }
        
      # Metriques des logs
      $logFiles = @()
      $totalLogSize = 0
      if (Test-Path $OptimizationConfig.LogsPath) {
         $logFiles = Get-ChildItem -Path $OptimizationConfig.LogsPath -File -Recurse -ErrorAction SilentlyContinue
         $totalLogSize = ($logFiles | Measure-Object -Property Length -Sum).Sum
      }
        
      $metrics = @{
         Timestamp = Get-Date
         System    = @{
            CPU    = @{
               Usage = if ($cpu.Average) { $cpu.Average } else { 0 }
            }
            Memory = @{
               Total = $memory.TotalVisibleMemorySize * 1KB
               Free  = $memory.FreePhysicalMemory * 1KB
               Usage = [math]::Round((1 - ($memory.FreePhysicalMemory / $memory.TotalVisibleMemorySize)) * 100, 2)
            }
            Disk   = @{
               Total = if ($disk) { $disk.Size } else { 0 }
               Free  = if ($disk) { $disk.FreeSpace } else { 0 }
               Usage = if ($disk) { [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 2) } else { 0 }
            }
         }
         Project   = @{
            Size           = $projectSize
            SizeMB         = [math]::Round($projectSize / 1MB, 2)
            FileCount      = $fileCount
            DirectoryCount = $directoryCount
         }
         Logs      = @{
            FileCount   = $logFiles.Count
            TotalSize   = $totalLogSize
            TotalSizeMB = [math]::Round($totalLogSize / 1MB, 2)
            LargestFile = if ($logFiles.Count -gt 0) { ($logFiles | Sort-Object Length -Descending | Select-Object -First 1).Length } else { 0 }
         }
      }
        
      return $metrics
   }
   catch {
      Write-PerformanceLog "Erreur lors de la collecte des metriques: $_" -Level "Error"
      return $null
   }
}

function Test-PerformanceIssues {
   param([hashtable]$Metrics)
    
   $issues = @()
    
   if (-not $Metrics) {
      return @("Impossible de collecter les metriques de performance")
   }
    
   # Verifier l'utilisation de la memoire
   if ($Metrics.System.Memory.Usage -gt $OptimizationConfig.OptimizationRules.MemoryThreshold) {
      $issues += "Utilisation memoire elevee: $($Metrics.System.Memory.Usage)%"
   }
    
   # Verifier l'utilisation du CPU
   if ($Metrics.System.CPU.Usage -gt $OptimizationConfig.OptimizationRules.CPUThreshold) {
      $issues += "Utilisation CPU elevee: $($Metrics.System.CPU.Usage)%"
   }
    
   # Verifier la taille du projet
   if ($Metrics.Project.Size -gt $OptimizationConfig.OptimizationRules.MaxDirectorySize) {
      $issues += "Taille du projet excessive: $($Metrics.Project.SizeMB) MB"
   }
    
   # Verifier les logs
   if ($Metrics.Logs.TotalSizeMB -gt $MaxLogSizeMB) {
      $issues += "Taille des logs excessive: $($Metrics.Logs.TotalSizeMB) MB"
   }
    
   if ($Metrics.Logs.FileCount -gt $OptimizationConfig.OptimizationRules.MaxLogFiles) {
      $issues += "Nombre de fichiers de log excessif: $($Metrics.Logs.FileCount)"
   }
    
   # Verifier les fichiers temporaires
   $tempFiles = @()
   if (Test-Path $OptimizationConfig.TempPath) {
      $tempFiles = Get-ChildItem -Path $OptimizationConfig.TempPath -Recurse -File -ErrorAction SilentlyContinue
   }
    
   if ($tempFiles.Count -gt $OptimizationConfig.OptimizationRules.MaxTempFiles) {
      $issues += "Nombre de fichiers temporaires excessif: $($tempFiles.Count)"
   }
    
   return $issues
}

function Invoke-PerformanceOptimization {
   param([hashtable]$Metrics)
    
   Write-PerformanceLog "Debut de l'optimisation des performances" -Level "Info"
    
   $optimizations = @()
    
   try {
      # Nettoyage des fichiers temporaires
      $tempPath = $OptimizationConfig.TempPath
      if (Test-Path $tempPath) {
         $tempFiles = Get-ChildItem -Path $tempPath -Recurse -File -ErrorAction SilentlyContinue
         if ($tempFiles.Count -gt 0) {
            $tempFiles | Remove-Item -Force -ErrorAction SilentlyContinue
            $optimizations += "Suppression de $($tempFiles.Count) fichiers temporaires"
            Write-PerformanceLog "Fichiers temporaires nettoyes: $($tempFiles.Count)" -Level "Success"
         }
      }
        
      # Rotation des logs
      if ($Metrics.Logs.TotalSizeMB -gt $MaxLogSizeMB) {
         $rotatedCount = Invoke-LogRotation
         if ($rotatedCount -gt 0) {
            $optimizations += "Rotation de $rotatedCount fichiers de log"
         }
      }
        
      # Nettoyage des fichiers selon les patterns
      $cleanedFiles = Invoke-PatternCleanup
      if ($cleanedFiles -gt 0) {
         $optimizations += "Suppression de $cleanedFiles fichiers de nettoyage"
      }
        
      # Nettoyage du cache
      $cacheCleared = Invoke-CacheCleanup
      if ($cacheCleared) {
         $optimizations += "Cache nettoye"
      }
        
      # Optimisation de la memoire (simulation)
      if ($Metrics.System.Memory.Usage -gt $OptimizationConfig.OptimizationRules.MemoryThreshold) {
         # En production, on pourrait declencher le garbage collector
         [System.GC]::Collect()
         $optimizations += "Garbage collection forcee"
         Write-PerformanceLog "Garbage collection executee" -Level "Success"
      }
        
      Write-PerformanceLog "Optimisations completees: $($optimizations.Count)" -Level "Success"
      return $optimizations
   }
   catch {
      Write-PerformanceLog "Erreur lors de l'optimisation: $_" -Level "Error"
      return @()
   }
}

function Invoke-LogRotation {
   try {
      $rotatedCount = 0
      $logsPath = $OptimizationConfig.LogsPath
        
      if (Test-Path $logsPath) {
         $logFiles = Get-ChildItem -Path $logsPath -File "*.log" -ErrorAction SilentlyContinue
            
         foreach ($logFile in $logFiles) {
            # Rotation si le fichier est trop volumineux ou trop ancien
            $sizeMB = [math]::Round($logFile.Length / 1MB, 2)
            $agedays = (Get-Date) - $logFile.LastWriteTime | Select-Object -ExpandProperty TotalDays
                
            if ($sizeMB -gt ($MaxLogSizeMB / 10) -or $agedays -gt $LogRetentionDays) {
               $rotatedName = "$($logFile.BaseName)-$(Get-Date -Format 'yyyyMMdd-HHmmss').log.old"
               $rotatedPath = Join-Path $logFile.DirectoryName $rotatedName
                    
               Move-Item -Path $logFile.FullName -Destination $rotatedPath -ErrorAction SilentlyContinue
               $rotatedCount++
                    
               Write-PerformanceLog "Log rotate: $($logFile.Name) -> $rotatedName" -Level "Info"
            }
         }
      }
        
      return $rotatedCount
   }
   catch {
      Write-PerformanceLog "Erreur lors de la rotation des logs: $_" -Level "Error"
      return 0
   }
}

function Invoke-PatternCleanup {
   try {
      $cleanedCount = 0
        
      foreach ($pattern in $OptimizationConfig.CleanupPatterns) {
         $files = Get-ChildItem -Path $OptimizationConfig.ProjectRoot -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue
            
         foreach ($file in $files) {
            # Verifier que le fichier n'est pas critique
            if ($file.LastWriteTime -lt (Get-Date).AddDays(-1)) {
               Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
               $cleanedCount++
            }
         }
      }
        
      if ($cleanedCount -gt 0) {
         Write-PerformanceLog "Fichiers nettoyes selon les patterns: $cleanedCount" -Level "Success"
      }
        
      return $cleanedCount
   }
   catch {
      Write-PerformanceLog "Erreur lors du nettoyage par patterns: $_" -Level "Error"
      return 0
   }
}

function Invoke-CacheCleanup {
   try {
      $cachePath = $OptimizationConfig.CachePath
        
      if (Test-Path $cachePath) {
         $cacheFiles = Get-ChildItem -Path $cachePath -Recurse -File -ErrorAction SilentlyContinue
            
         if ($cacheFiles.Count -gt 0) {
            $cacheFiles | Remove-Item -Force -ErrorAction SilentlyContinue
            Write-PerformanceLog "Cache nettoye: $($cacheFiles.Count) fichiers supprimes" -Level "Success"
            return $true
         }
      }
        
      return $false
   }
   catch {
      Write-PerformanceLog "Erreur lors du nettoyage du cache: $_" -Level "Error"
      return $false
   }
}

function Save-PerformanceMetrics {
   param([hashtable]$Metrics, [array]$Issues, [array]$Optimizations)
    
   try {
      $report = @{
         Timestamp        = Get-Date
         Metrics          = $Metrics
         Issues           = $Issues
         Optimizations    = $Optimizations
         PerformanceScore = Get-PerformanceScore -Metrics $Metrics -Issues $Issues
      }
        
      $report | ConvertTo-Json -Depth 5 | Out-File -FilePath $OptimizationConfig.PerformanceFile -Encoding utf8
      Write-PerformanceLog "Metriques de performance sauvegardees" -Level "Success"
   }
   catch {
      Write-PerformanceLog "Erreur lors de la sauvegarde: $_" -Level "Error"
   }
}

function Get-PerformanceScore {
   param([hashtable]$Metrics, [array]$Issues)
    
   $baseScore = 100
   $penalties = @{
      "Utilisation memoire elevee"              = 15
      "Utilisation CPU elevee"                  = 10
      "Taille du projet excessive"              = 5
      "Taille des logs excessive"               = 10
      "Nombre de fichiers de log excessif"      = 5
      "Nombre de fichiers temporaires excessif" = 5
   }
    
   $finalScore = $baseScore
   foreach ($issue in $Issues) {
      foreach ($penalty in $penalties.Keys) {
         if ($issue -like "*$penalty*") {
            $finalScore -= $penalties[$penalty]
            break
         }
      }
   }
    
   return [math]::Max(0, $finalScore)
}

function Show-PerformanceReport {
   param([hashtable]$Metrics, [array]$Issues, [array]$Optimizations)
    
   $score = Get-PerformanceScore -Metrics $Metrics -Issues $Issues
    
   Write-Host "`n" + "="*80 -ForegroundColor Cyan
   Write-Host " 📊 RAPPORT DE PERFORMANCE - Plan Dev v41" -ForegroundColor Cyan
   Write-Host "="*80 -ForegroundColor Cyan
    
   Write-Host "`n🎯 SCORE DE PERFORMANCE: $score/100" -ForegroundColor $(
      if ($score -ge 90) { "Green" }
      elseif ($score -ge 70) { "Yellow" }
      else { "Red" }
   )
    
   if ($Metrics) {
      Write-Host "`n💻 METRIQUES SYSTEME:" -ForegroundColor White
      Write-Host "   CPU: $($Metrics.System.CPU.Usage)%" -ForegroundColor White
      Write-Host "   Memoire: $($Metrics.System.Memory.Usage)%" -ForegroundColor $(if ($Metrics.System.Memory.Usage -gt 75) { "Red" } else { "Green" })
      Write-Host "   Disque: $($Metrics.System.Disk.Usage)%" -ForegroundColor $(if ($Metrics.System.Disk.Usage -gt 85) { "Red" } else { "Green" })
        
      Write-Host "`n📁 METRIQUES PROJET:" -ForegroundColor White
      Write-Host "   Taille: $($Metrics.Project.SizeMB) MB" -ForegroundColor White
      Write-Host "   Fichiers: $($Metrics.Project.FileCount)" -ForegroundColor White
      Write-Host "   Repertoires: $($Metrics.Project.DirectoryCount)" -ForegroundColor White
        
      Write-Host "`n📋 LOGS:" -ForegroundColor White
      Write-Host "   Fichiers: $($Metrics.Logs.FileCount)" -ForegroundColor White
      Write-Host "   Taille totale: $($Metrics.Logs.TotalSizeMB) MB" -ForegroundColor White
   }
    
   if ($Issues.Count -gt 0) {
      Write-Host "`n⚠️  PROBLEMES DETECTES:" -ForegroundColor Red
      foreach ($issue in $Issues) {
         Write-Host "   • $issue" -ForegroundColor Red
      }
   }
   else {
      Write-Host "`n✅ AUCUN PROBLEME DETECTE" -ForegroundColor Green
   }
    
   if ($Optimizations.Count -gt 0) {
      Write-Host "`n🔧 OPTIMISATIONS APPLIQUEES:" -ForegroundColor Green
      foreach ($optimization in $Optimizations) {
         Write-Host "   • $optimization" -ForegroundColor Green
      }   
   }
    
   Write-Host "`n" + "="*80 -ForegroundColor Cyan
}

# ===== FONCTION PRINCIPALE =====

function Start-PerformanceOptimization {
   try {
      Initialize-PerformanceSystem
        
      switch ($Mode) {
         "Analyze" {
            $metrics = Get-PerformanceMetrics
            $issues = Test-PerformanceIssues -Metrics $metrics
            Show-PerformanceReport -Metrics $metrics -Issues $issues -Optimizations @()
            Save-PerformanceMetrics -Metrics $metrics -Issues $issues -Optimizations @()
         }
            
         "Optimize" {
            $metrics = Get-PerformanceMetrics
            $issues = Test-PerformanceIssues -Metrics $metrics
            $optimizations = @()
                
            if ($issues.Count -gt 0 -or $AutoOptimize) {
               Write-PerformanceLog "Application des optimisations..." -Level "Info"
               $optimizations = Invoke-PerformanceOptimization -Metrics $metrics
                    
               # Re-collecter les metriques apres optimisation
               Start-Sleep -Seconds 2
               $newMetrics = Get-PerformanceMetrics
               $newIssues = Test-PerformanceIssues -Metrics $newMetrics
                    
               Show-PerformanceReport -Metrics $newMetrics -Issues $newIssues -Optimizations $optimizations
               Save-PerformanceMetrics -Metrics $newMetrics -Issues $newIssues -Optimizations $optimizations
            }
            else {
               Write-Host "Aucune optimisation necessaire" -ForegroundColor Green
               Show-PerformanceReport -Metrics $metrics -Issues $issues -Optimizations @()
            }
         }
            
         "Monitor" {
            Write-Host "Mode surveillance des performances..." -ForegroundColor Green
            Write-Host "Appuyez sur Ctrl+C pour arreter" -ForegroundColor Yellow
                
            while ($true) {
               $metrics = Get-PerformanceMetrics
               $issues = Test-PerformanceIssues -Metrics $metrics
                    
               if ($issues.Count -gt 0) {
                  Write-PerformanceLog "Problemes detectes: $($issues.Count)" -Level "Warning"
                        
                  if ($AutoOptimize) {
                     Write-PerformanceLog "Optimisation automatique..." -Level "Info"
                     Invoke-PerformanceOptimization -Metrics $metrics | Out-Null
                  }
               }
                    
               Write-PerformanceLog "CPU: $($metrics.System.CPU.Usage)% | RAM: $($metrics.System.Memory.Usage)% | Disque: $($metrics.System.Disk.Usage)%" -Level "Info"
               Start-Sleep -Seconds 30
            }
         }
            
         "Clean" {
            Write-PerformanceLog "Nettoyage complet..." -Level "Info"
            $metrics = Get-PerformanceMetrics
            $optimizations = Invoke-PerformanceOptimization -Metrics $metrics
                
            Write-Host "`nNettoyage termine:" -ForegroundColor Green
            foreach ($opt in $optimizations) {
               Write-Host "   • $opt" -ForegroundColor Green
            }
         }
            
         "Report" {
            if (Test-Path $OptimizationConfig.PerformanceFile) {
               $report = Get-Content $OptimizationConfig.PerformanceFile | ConvertFrom-Json
               Show-PerformanceReport -Metrics $report.Metrics -Issues $report.Issues -Optimizations $report.Optimizations
            }
            else {
               Write-Host "Aucun rapport de performance disponible. Executez d'abord 'Analyze'" -ForegroundColor Yellow
            }
         }
            
         default {
            Write-Host "Mode invalide. Utilisez: Analyze, Optimize, Monitor, Clean, Report" -ForegroundColor Red
            return 1
         }
      }
        
      return 0
   }
   catch {
      Write-PerformanceLog "Erreur critique: $_" -Level "Error"
      return 1
   }
}

# ===== POINT D'ENTREE =====

exit (Start-PerformanceOptimization)
