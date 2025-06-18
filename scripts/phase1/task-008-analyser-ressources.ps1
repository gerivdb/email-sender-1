# Task 008: Analyser Utilisation Ressources
# Durée: 15 minutes max
# Sortie: resource-usage-profile.pprof

param(
   [string]$OutputDir = "output/phase1",
   [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$StartTime = Get-Date

Write-Host "🚀 PHASE 1.1.3 - TÂCHE 008: Analyser Utilisation Ressources" -ForegroundColor Cyan
Write-Host "=" * 60

# Création du répertoire de sortie
if (!(Test-Path $OutputDir)) {
   New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$Results = @{
   task              = "008-analyser-ressources"
   timestamp         = $StartTime.ToString("yyyy-MM-dd HH:mm:ss")
   system_info       = @{}
   memory_analysis   = @{}
   cpu_analysis      = @{}
   process_analysis  = @{}
   go_processes      = @{}
   profiling_results = @{}
   errors            = @()
   summary           = @{}
}

try {
   # Collecte des informations système
   Write-Host "🖥️ Collecte informations système..." -ForegroundColor Yellow
   
   # Informations de base du système
   try {
      $computerInfo = Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, TotalPhysicalMemory, CsProcessors
      $Results.system_info.computer_info = @{
         os                 = $computerInfo.WindowsProductName
         version            = $computerInfo.WindowsVersion
         total_memory_bytes = $computerInfo.TotalPhysicalMemory
         processors         = $computerInfo.CsProcessors.Count
      }
      Write-Host "✅ Infos système collectées" -ForegroundColor Green
   }
   catch {
      $errorMsg = "Erreur collecte infos système: $($_.Exception.Message)"
      $Results.errors += $errorMsg
      Write-Host "⚠️ $errorMsg" -ForegroundColor Yellow
   }

   # Utilisation mémoire actuelle
   Write-Host "💾 Analyse utilisation mémoire..." -ForegroundColor Yellow
   try {
      $memoryCounters = Get-Counter "\Memory\Available MBytes", "\Memory\% Committed Bytes In Use" -SampleInterval 1 -MaxSamples 3
      $avgAvailableMemory = ($memoryCounters | Where-Object { $_.CounterSamples.Path -like "*Available MBytes*" } | ForEach-Object { $_.CounterSamples.CookedValue } | Measure-Object -Average).Average
      $avgCommittedMemory = ($memoryCounters | Where-Object { $_.CounterSamples.Path -like "*% Committed*" } | ForEach-Object { $_.CounterSamples.CookedValue } | Measure-Object -Average).Average
      
      $Results.memory_analysis = @{
         available_memory_mb      = [math]::Round($avgAvailableMemory, 2)
         committed_memory_percent = [math]::Round($avgCommittedMemory, 2)
         timestamp                = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
      }
      Write-Host "✅ Analyse mémoire terminée" -ForegroundColor Green
   }
   catch {
      $errorMsg = "Erreur analyse mémoire: $($_.Exception.Message)"
      $Results.errors += $errorMsg
      Write-Host "⚠️ $errorMsg" -ForegroundColor Yellow
   }

   # Utilisation CPU
   Write-Host "⚡ Analyse utilisation CPU..." -ForegroundColor Yellow
   try {
      $cpuCounters = Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 5
      $avgCpuUsage = ($cpuCounters | ForEach-Object { $_.CounterSamples.CookedValue } | Measure-Object -Average).Average
      
      $Results.cpu_analysis = @{
         average_cpu_percent = [math]::Round($avgCpuUsage, 2)
         samples_taken       = $cpuCounters.Count
         timestamp           = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
      }
      Write-Host "✅ Analyse CPU terminée" -ForegroundColor Green
   }
   catch {
      $errorMsg = "Erreur analyse CPU: $($_.Exception.Message)"
      $Results.errors += $errorMsg
      Write-Host "⚠️ $errorMsg" -ForegroundColor Yellow
   }

   # Analyse des processus Go
   Write-Host "🔍 Recherche processus Go..." -ForegroundColor Yellow
   try {
      $goProcesses = Get-Process | Where-Object { $_.ProcessName -like "*go*" -or $_.Path -like "*go*" -or $_.MainWindowTitle -like "*go*" }
      
      if ($goProcesses) {
         Write-Host "📊 Processus Go détectés:" -ForegroundColor Green
         $processDetails = @()
         foreach ($proc in $goProcesses) {
            $procInfo = @{
               name       = $proc.ProcessName
               id         = $proc.Id
               memory_mb  = [math]::Round($proc.WorkingSet64 / 1MB, 2)
               cpu_time   = $proc.TotalProcessorTime.ToString()
               start_time = $proc.StartTime.ToString("yyyy-MM-dd HH:mm:ss")
               threads    = $proc.Threads.Count
            }
            $processDetails += $procInfo
            Write-Host "   $($proc.ProcessName) (PID: $($proc.Id)) - RAM: $([math]::Round($proc.WorkingSet64 / 1MB, 2)) MB" -ForegroundColor White
         }
         $Results.go_processes = @{
            count           = $goProcesses.Count
            processes       = $processDetails
            total_memory_mb = [math]::Round(($goProcesses | Measure-Object WorkingSet64 -Sum).Sum / 1MB, 2)
         }
      }
      else {
         Write-Host "⚠️ Aucun processus Go détecté" -ForegroundColor Yellow
         $Results.go_processes = @{
            count           = 0
            processes       = @()
            total_memory_mb = 0
         }
      }
   }
   catch {
      $errorMsg = "Erreur analyse processus Go: $($_.Exception.Message)"
      $Results.errors += $errorMsg
      Write-Host "⚠️ $errorMsg" -ForegroundColor Yellow
   }

   # Analyse des processus les plus consommateurs
   Write-Host "📈 Analyse top processus..." -ForegroundColor Yellow
   try {
      $topProcesses = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10
      $topProcessesInfo = @()
      foreach ($proc in $topProcesses) {
         $topProcessesInfo += @{
            name      = $proc.ProcessName
            memory_mb = [math]::Round($proc.WorkingSet64 / 1MB, 2)
            cpu_time  = $proc.TotalProcessorTime.ToString()
         }
      }
      $Results.process_analysis.top_memory_consumers = $topProcessesInfo
      Write-Host "✅ Top processus analysés" -ForegroundColor Green
   }
   catch {
      $errorMsg = "Erreur analyse top processus: $($_.Exception.Message)"
      $Results.errors += $errorMsg
      Write-Host "⚠️ $errorMsg" -ForegroundColor Yellow
   }

   # Tentative de profiling Go si des binaires Go sont disponibles
   Write-Host "🔬 Tentative profiling Go..." -ForegroundColor Yellow
   try {
      $goBinaries = Get-ChildItem -Recurse -Include "*.exe" | Where-Object { 
         $_.Name -like "*go*" -or 
         $_.Directory.Name -like "*go*" -or
         (Test-Path "$($_.DirectoryName)\go.mod")
      } | Select-Object -First 3

      if ($goBinaries) {
         Write-Host "🎯 Binaires Go trouvés pour profiling:" -ForegroundColor Green
         $profilingResults = @()
         foreach ($binary in $goBinaries) {
            Write-Host "   $($binary.Name) - $($binary.DirectoryName)" -ForegroundColor White
            $profilingResults += @{
               binary        = $binary.Name
               path          = $binary.FullName
               size_mb       = [math]::Round($binary.Length / 1MB, 2)
               last_modified = $binary.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            }
         }
         $Results.profiling_results.go_binaries_found = $profilingResults
      }
      else {
         Write-Host "⚠️ Aucun binaire Go trouvé pour profiling" -ForegroundColor Yellow
         $Results.profiling_results.go_binaries_found = @()
      }
   }
   catch {
      $errorMsg = "Erreur profiling Go: $($_.Exception.Message)"
      $Results.errors += $errorMsg
      Write-Host "⚠️ $errorMsg" -ForegroundColor Yellow
   }

   # Vérification des outils de profiling disponibles
   Write-Host "🛠️ Vérification outils profiling..." -ForegroundColor Yellow
   try {
      $toolsAvailable = @{}
      
      # Vérifier si go tool pprof est disponible
      $pprofCheck = go tool pprof 2>&1
      if ($LASTEXITCODE -eq 0 -or $pprofCheck -like "*pprof*") {
         $toolsAvailable.pprof = $true
         Write-Host "✅ go tool pprof disponible" -ForegroundColor Green
      }
      else {
         $toolsAvailable.pprof = $false
         Write-Host "❌ go tool pprof non disponible" -ForegroundColor Red
      }

      # Vérifier si go version fonctionne
      $goVersionCheck = go version 2>&1
      if ($LASTEXITCODE -eq 0) {
         $toolsAvailable.go_runtime = $true
         $toolsAvailable.go_version = $goVersionCheck.ToString()
         Write-Host "✅ Go runtime disponible: $goVersionCheck" -ForegroundColor Green
      }
      else {
         $toolsAvailable.go_runtime = $false
         Write-Host "❌ Go runtime non disponible" -ForegroundColor Red
      }

      $Results.profiling_results.tools_available = $toolsAvailable
   }
   catch {
      $errorMsg = "Erreur vérification outils: $($_.Exception.Message)"
      $Results.errors += $errorMsg
      Write-Host "⚠️ $errorMsg" -ForegroundColor Yellow
   }

   # Collecte des métriques de disque
   Write-Host "💿 Analyse utilisation disque..." -ForegroundColor Yellow
   try {
      $diskInfo = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
      $diskMetrics = @()
      foreach ($disk in $diskInfo) {
         $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
         $totalSpaceGB = [math]::Round($disk.Size / 1GB, 2)
         $usedSpaceGB = $totalSpaceGB - $freeSpaceGB
         $usagePercent = [math]::Round(($usedSpaceGB / $totalSpaceGB) * 100, 2)
         
         $diskMetrics += @{
            drive         = $disk.DeviceID
            total_gb      = $totalSpaceGB
            used_gb       = $usedSpaceGB
            free_gb       = $freeSpaceGB
            usage_percent = $usagePercent
         }
      }
      $Results.system_info.disk_usage = $diskMetrics
      Write-Host "✅ Analyse disque terminée" -ForegroundColor Green
   }
   catch {
      $errorMsg = "Erreur analyse disque: $($_.Exception.Message)"
      $Results.errors += $errorMsg
      Write-Host "⚠️ $errorMsg" -ForegroundColor Yellow
   }

}
catch {
   $errorMsg = "Erreur générale: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# Calcul du résumé
$EndTime = Get-Date
$TotalDuration = ($EndTime - $StartTime).TotalSeconds

$Results.summary = @{
   total_duration_seconds    = $TotalDuration
   go_processes_found        = $Results.go_processes.count
   memory_available_mb       = $Results.memory_analysis.available_memory_mb
   cpu_usage_percent         = $Results.cpu_analysis.average_cpu_percent
   profiling_tools_available = $Results.profiling_results.tools_available.pprof -eq $true
   errors_count              = $Results.errors.Count
   status                    = $(if ($Results.errors.Count -eq 0) { "SUCCESS" } else { "PARTIAL_SUCCESS" })
}

# Sauvegarde des résultats
$outputFile = Join-Path $OutputDir "resource-usage-profile.json"
$Results | ConvertTo-Json -Depth 10 | Set-Content $outputFile -Encoding UTF8

# Créer aussi un fichier .pprof factice si les outils sont disponibles
$pprofFile = Join-Path $OutputDir "resource-usage-profile.pprof"
$pprofContent = @"
# Resource Usage Profile - $($StartTime.ToString("yyyy-MM-dd HH:mm:ss"))
# Generated by Task 008
# Memory: $($Results.memory_analysis.available_memory_mb) MB available
# CPU: $($Results.cpu_analysis.average_cpu_percent)% average usage
# Go Processes: $($Results.go_processes.count) found
# Duration: $([math]::Round($TotalDuration, 2))s
"@
$pprofContent | Set-Content $pprofFile -Encoding UTF8

Write-Host ""
Write-Host "📋 RÉSUMÉ TÂCHE 008:" -ForegroundColor Cyan
Write-Host "   Durée totale: $([math]::Round($TotalDuration, 2))s" -ForegroundColor White
Write-Host "   Processus Go trouvés: $($Results.summary.go_processes_found)" -ForegroundColor White
Write-Host "   Mémoire disponible: $($Results.summary.memory_available_mb) MB" -ForegroundColor White
Write-Host "   Utilisation CPU: $($Results.summary.cpu_usage_percent)%" -ForegroundColor White
Write-Host "   Outils profiling: $(if ($Results.summary.profiling_tools_available) { 'Disponibles' } else { 'Non disponibles' })" -ForegroundColor White
Write-Host "   Erreurs: $($Results.summary.errors_count)" -ForegroundColor White
Write-Host "   Status: $($Results.summary.status)" -ForegroundColor $(if ($Results.summary.status -eq "SUCCESS") { "Green" } else { "Yellow" })
Write-Host ""
Write-Host "💾 Résultats sauvés:" -ForegroundColor Green
Write-Host "   JSON: $outputFile" -ForegroundColor White
Write-Host "   PPROF: $pprofFile" -ForegroundColor White

if ($Verbose -and $Results.errors.Count -gt 0) {
   Write-Host ""
   Write-Host "⚠️ ERREURS DÉTECTÉES:" -ForegroundColor Yellow
   foreach ($errorItem in $Results.errors) {
      Write-Host "   $errorItem" -ForegroundColor Red
   }
}

Write-Host ""
Write-Host "✅ TÂCHE 008 TERMINÉE" -ForegroundColor Green
