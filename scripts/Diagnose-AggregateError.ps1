# Diagnostic d'Erreur d'Agregation - EMAIL_SENDER_1
param([switch]$Fix = $false)

Write-Host "=== DIAGNOSTIC ERREUR AGREGATION ===" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date)" -ForegroundColor Gray

# 1. Verification Git
Write-Host ""
Write-Host "1. ETAT GIT:" -ForegroundColor Yellow
try {
   $gitStatus = git status --porcelain 2>$null
   if ($gitStatus) {
      Write-Host "  Fichiers non suivis/modifies detectes:" -ForegroundColor Yellow
      $gitStatus | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
   }
   else {
      Write-Host "  Repository propre" -ForegroundColor Green
   }
    
   $branch = git branch --show-current 2>$null
   Write-Host "  Branche: $branch" -ForegroundColor $(if ($branch -eq "dev") { "Green" } else { "Yellow" })
}
catch {
   Write-Host "  ERREUR Git: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Verification Docker
Write-Host ""
Write-Host "2. ETAT DOCKER:" -ForegroundColor Yellow
try {
   $dockerVersion = docker --version 2>$null
   Write-Host "  Version: $dockerVersion" -ForegroundColor Green
    
   $dockerService = Get-Service "com.docker.service" -ErrorAction SilentlyContinue
   if ($dockerService) {
      Write-Host "  Service Docker: $($dockerService.Status)" -ForegroundColor $(if ($dockerService.Status -eq "Running") { "Green" } else { "Red" })
   }
    
   try {
      $containers = docker ps -a --format "table {{.Names}}\t{{.Status}}" 2>$null
      if ($containers) {
         Write-Host "  Conteneurs:" -ForegroundColor Gray
         $containers | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
      }
   }
   catch {
      Write-Host "  Docker Engine non accessible (Desktop probablement arrete)" -ForegroundColor Red
   }
}
catch {
   Write-Host "  ERREUR Docker: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Verification des processus
Write-Host ""
Write-Host "3. PROCESSUS CRITIQUES:" -ForegroundColor Yellow
$criticalProcesses = @("git", "docker", "node", "npm", "code")
foreach ($proc in $criticalProcesses) {
   $running = Get-Process -Name $proc -ErrorAction SilentlyContinue
   if ($running) {
      Write-Host "  ${proc}: $($running.Count) instance(s)" -ForegroundColor Green
   }
   else {
      Write-Host "  ${proc}: Non actif" -ForegroundColor Gray
   }
}

# 4. Verification des fichiers du projet
Write-Host ""
Write-Host "4. FICHIERS CRITIQUES PLAN V54:" -ForegroundColor Yellow
$criticalFiles = @(
   "PHASE_1_SMART_INFRASTRUCTURE_COMPLETE.md",
   "PHASE_2_ADVANCED_MONITORING_COMPLETE.md", 
   "PHASE_3_IDE_INTEGRATION_FINAL_COMPLETE.md",
   "PHASE_4_IMPLEMENTATION_COMPLETE.md",
   "development\managers\advanced-autonomy-manager\config\infrastructure_config.yaml"
)

foreach ($file in $criticalFiles) {
   if (Test-Path $file) {
      Write-Host "  OK: $file" -ForegroundColor Green
   }
   else {
      Write-Host "  MISSING: $file" -ForegroundColor Red
   }
}

# 5. Verification de l'espace disque
Write-Host ""
Write-Host "5. ESPACE DISQUE:" -ForegroundColor Yellow
$disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='D:'"
if ($disk) {
   $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
   $totalGB = [math]::Round($disk.Size / 1GB, 2)
   $freePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 1)
   Write-Host "  Disque D: $freeGB GB libre sur $totalGB GB ($freePercent%)" -ForegroundColor $(if ($freePercent -gt 10) { "Green" } else { "Red" })
}

# 6. Suggestions de resolution
Write-Host ""
Write-Host "6. DIAGNOSTIC ERREUR AGREGATION:" -ForegroundColor Yellow

$issues = @()
if ((Get-Service "com.docker.service" -ErrorAction SilentlyContinue).Status -ne "Running") {
   $issues += "Docker Desktop arrete"
}

$gitStatusOutput = git status --porcelain 2>$null
if ($gitStatusOutput) {
   $issues += "Fichiers Git non commites"
}

if ($issues.Count -eq 0) {
   Write-Host "  Aucun probleme detecte" -ForegroundColor Green
}
else {
   Write-Host "  Problemes detectes:" -ForegroundColor Red
   foreach ($issue in $issues) {
      Write-Host "    - $issue" -ForegroundColor Red
   }
}

# 7. Actions correctives automatiques
if ($Fix -and $issues.Count -gt 0) {
   Write-Host ""
   Write-Host "7. ACTIONS CORRECTIVES:" -ForegroundColor Yellow
    
   # Demarrer Docker si arrete
   if ($issues -contains "Docker Desktop arrete") {
      Write-Host "  Tentative de demarrage Docker Desktop..." -ForegroundColor Yellow
      try {
         Start-Process "Docker Desktop" -ErrorAction SilentlyContinue
         Start-Sleep 3
         Write-Host "  Docker Desktop lance (peut prendre quelques minutes)" -ForegroundColor Green
      }
      catch {
         Write-Host "  Impossible de demarrer Docker Desktop automatiquement" -ForegroundColor Red
      }
   }
   # Commit des fichiers en attente
   $gitStatusOutput2 = git status --porcelain 2>$null
   if ($gitStatusOutput2) {
      Write-Host "  Ajout des fichiers non suivis..." -ForegroundColor Yellow
      try {
         git add . 2>$null
         Write-Host "  Fichiers ajoutes" -ForegroundColor Green
      }
      catch {
         Write-Host "  Erreur lors de l'ajout des fichiers" -ForegroundColor Red
      }
   }
}

Write-Host ""
Write-Host "=== FIN DIAGNOSTIC ===" -ForegroundColor Cyan

if ($issues.Count -eq 0) {
   Write-Host "STATUT: SYSTEME OPERATIONNEL" -ForegroundColor Green
   exit 0
}
else {
   Write-Host "STATUT: PROBLEMES DETECTES - Utilisez -Fix pour tenter une correction automatique" -ForegroundColor Yellow
   exit 1
}
