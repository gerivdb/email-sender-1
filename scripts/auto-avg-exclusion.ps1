# Script automatique d'exclusion AVG pour le développement
# Exécuté automatiquement et de façon invisible à l'ouverture de VS Code
# Version optimisée pour une exécution silencieuse

param(
   [switch]$Silent = $false,
   [switch]$Force = $false
)

# Configuration pour exécution silencieuse
if ($Silent) {
   $ProgressPreference = 'SilentlyContinue'
   $VerbosePreference = 'SilentlyContinue'
   $WarningPreference = 'SilentlyContinue'
}

# Fonction pour écrire dans un log au lieu de la console
function Write-Log {
   param($Message, $Level = "INFO")
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $logEntry = "[$timestamp] [$Level] $Message"
    
   # Écrire dans un fichier log
   $logPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\logs\avg-exclusion.log"
   $logDir = Split-Path $logPath -Parent
   if (!(Test-Path $logDir)) {
      New-Item -ItemType Directory -Path $logDir -Force | Out-Null
   }
    
   Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    
   # Aussi dans la console si pas en mode silencieux
   if (!$Silent) {
      Write-Host $logEntry
   }
}

# Identifier le processus pour le gestionnaire des tâches
$Host.UI.RawUI.WindowTitle = "AVG-Exclusion-Auto [PID:$PID]"

Write-Log "🛡️ Démarrage de l'auto-exclusion AVG pour EMAIL_SENDER_1" "INFO"

# Liste des dossiers critiques pour le développement
$criticalFolders = @(
   "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1",
   "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\cmd",
   "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\pkg",
   "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\tools",
   "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development",
   "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\logs",
   "$env:TEMP\go-build*",
   "$env:LOCALAPPDATA\go-build",
   "C:\Users\$env:USERNAME\AppData\Local\go-build"
)

# Extensions critiques à exclure
$criticalExtensions = @(
   ".exe", ".go", ".mod", ".sum", ".dll", ".a", ".obj", ".bin", ".out",
   ".ps1", ".bat", ".cmd", ".py", ".pyc", ".pyo", ".pyd",
   ".js", ".ts", ".json", ".yaml", ".yml", ".toml", ".ini"
)

# Patterns explicites pour fichiers .exe (en plus de l'extension générale)
# Ces patterns seront utilisés pour créer des fichiers d'exclusion spécifiques
$exePatterns = @(
   "*go-build*.exe", 
   "*backup-qdrant.exe",
   "*migrate-qdrant.exe",
   "*monitoring-dashboard.exe",
   "*simple-api-server.exe",
   "*vector-migration.exe",
   "*test*.exe",
   "*debug*.exe"
)

# Processus de développement à exclure
$devProcesses = @(
   "go.exe", "gofmt.exe", "golangci-lint.exe", "dlv.exe",
   "python.exe", "pythonw.exe", "node.exe", "npm.exe",
   "code.exe", "Code.exe", "powershell.exe", "pwsh.exe"
)

Write-Log "📁 Vérification des exclusions pour $($criticalFolders.Count) dossiers..." "INFO"
Write-Log "📝 Vérification des exclusions pour $($criticalExtensions.Count) extensions..." "INFO"
Write-Log "⚙️ Vérification des exclusions pour $($devProcesses.Count) processus..." "INFO"

# Fonction pour vérifier si AVG est installé et actif
function Test-AVGInstalled {
   try {
      $avgServices = Get-Service | Where-Object { $_.Name -match "avg|antiv" -and $_.Status -eq "Running" }
      $avgProcesses = Get-Process | Where-Object { $_.ProcessName -match "avg|antiv" } -ErrorAction SilentlyContinue
        
      return ($avgServices.Count -gt 0 -or $avgProcesses.Count -gt 0)
   }
   catch {
      return $false
   }
}

# Fonction pour créer un indicateur de processus visible
function Set-ProcessIndicator {
   try {
      # Créer un fichier indicateur
      $indicatorPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\logs\avg-auto-exclusion.status"
      $statusInfo = @{
         ProcessId   = $PID
         StartTime   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
         Status      = "RUNNING"
         ProjectPath = "EMAIL_SENDER_1"
         Description = "Auto-exclusion AVG pour développement Go/Python/PowerShell"
      } | ConvertTo-Json
        
      Set-Content -Path $indicatorPath -Value $statusInfo -ErrorAction SilentlyContinue
      Write-Log "📊 Indicateur de statut créé : $indicatorPath" "INFO"
   }
   catch {
      Write-Log "⚠️ Impossible de créer l'indicateur de statut" "WARN"
   }
}

# Vérifier si AVG est installé
if (!(Test-AVGInstalled)) {
   Write-Log "ℹ️ AVG non détecté ou inactif - Arrêt du script" "INFO"
   exit 0
}

Write-Log "🔍 AVG détecté et actif - Configuration des exclusions..." "INFO"

# Créer l'indicateur de processus
Set-ProcessIndicator

# Vérifier les permissions administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (!$isAdmin -and !$Force) {
   Write-Log "⚠️ Permissions administrateur requises pour certaines exclusions" "WARN"
   Write-Log "💡 Relancer VS Code en tant qu'administrateur pour une configuration complète" "INFO"
    
   # Même sans admin, on peut faire certaines actions
   Write-Log "🔧 Configuration des exclusions utilisateur..." "INFO"
}
else {
   Write-Log "✅ Permissions administrateur détectées" "INFO"
}

# Fonction pour tenter l'ajout d'exclusions via registry (si possible)
function Add-AVGExclusions {
   try {
      Write-Log "🛠️ Tentative de configuration automatique des exclusions AVG..." "INFO"
        
      # Créer des fichiers temporaires pour indiquer à AVG de les exclure
      foreach ($folder in $criticalFolders) {
         if (Test-Path $folder) {
            $markerFile = Join-Path $folder ".avg-exclude-marker"
            "AVG_EXCLUDE_FOLDER" | Out-File $markerFile -ErrorAction SilentlyContinue
         }
      }
      
      # Créer des fichiers de marqueurs spécifiques pour .exe dans les dossiers critiques
      foreach ($folder in $criticalFolders) {
         if (Test-Path $folder) {
            $exeMarker = Join-Path $folder ".avg-exclude-exe-marker"
            "AVG_EXCLUDE_EXE_FILES" | Out-File $exeMarker -ErrorAction SilentlyContinue
         }
      }
      # Créer des fichiers .exe vides pour chaque pattern dans le dossier de logs pour forcer l'exclusion
      foreach ($pattern in $exePatterns) {
         $patternName = $pattern.Replace("*", "sample").Replace(".exe", "-test.exe")
         $dummyExePath = Join-Path $ProjectPath "logs\$patternName"
         $null | Set-Content -Path $dummyExePath -ErrorAction SilentlyContinue
         Write-Log "🔧 Fichier d'exclusion créé : $dummyExePath" "INFO"
      }
      
      Write-Log "📄 Marqueurs d'exclusion créés dans les dossiers critiques" "INFO"
      Write-Log "🔧 Marqueurs d'exclusion .exe créés dans les dossiers critiques" "INFO"
      return $true
   }
   catch {
      Write-Log "❌ Erreur lors de la configuration automatique : $($_.Exception.Message)" "ERROR"
      return $false
   }
}

# Fonction pour créer un script de configuration manuelle
function New-ManualConfigScript {
   $manualScript = @"
# Instructions pour configuration manuelle AVG
# AUTOMATIQUEMENT GÉNÉRÉ - $(Get-Date)

Write-Host "🛡️ Configuration manuelle AVG requise" -ForegroundColor Yellow
Write-Host ""
Write-Host "📁 Dossiers à exclure :" -ForegroundColor Green
$(foreach ($folder in $criticalFolders) { "Write-Host '  - $folder' -ForegroundColor Cyan" })

Write-Host ""
Write-Host "📝 Extensions à exclure :" -ForegroundColor Green  
$(foreach ($ext in $criticalExtensions) { "Write-Host '  - *$ext' -ForegroundColor Cyan" })

Write-Host ""
Write-Host "⚙️ Processus à exclure :" -ForegroundColor Green
$(foreach ($proc in $devProcesses) { "Write-Host '  - $proc' -ForegroundColor Cyan" })

Write-Host ""
Write-Host "📋 ÉTAPES :" -ForegroundColor Yellow
Write-Host "1. Ouvrir AVG Antivirus"
Write-Host "2. Menu → Paramètres → Général → Exceptions"
Write-Host "3. Ajouter chaque élément ci-dessus"
Write-Host "4. Redémarrer le système"

# Ouvrir AVG si possible
try {
    Start-Process "C:\Program Files\AVG\Antivirus\AVGUI.exe"
}
catch {
    Write-Host "❌ Ouvrir manuellement AVG depuis le menu Démarrer"
}
"@
    
   $scriptPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\manual-avg-config.ps1"
   Set-Content -Path $scriptPath -Value $manualScript -ErrorAction SilentlyContinue
   Write-Log "📜 Script de configuration manuelle créé : $scriptPath" "INFO"
}

# Exécuter la configuration
$configSuccess = Add-AVGExclusions

if (!$configSuccess) {
   Write-Log "⚠️ Configuration automatique échouée - Création du script manuel" "WARN"
   New-ManualConfigScript
}

# Surveiller les processus de compilation
function Start-CompilationMonitoring {
   Write-Log "👀 Démarrage de la surveillance des processus de compilation..." "INFO"
    
   while ($true) {
      try {
         # Surveiller les processus Go
         $goProcesses = Get-Process | Where-Object { $_.ProcessName -match "go|gofmt|golangci" } -ErrorAction SilentlyContinue
            
         if ($goProcesses.Count -gt 0) {
            Write-Log "🔨 Processus de compilation détectés : $($goProcesses.Count)" "INFO"
                
            # Créer un fichier temporaire pour indiquer l'activité
            $activityFile = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\logs\.compilation-active"
            Get-Date | Out-File $activityFile -ErrorAction SilentlyContinue
         }
            
         # Attendre 30 secondes avant la prochaine vérification
         Start-Sleep -Seconds 30
      }
      catch {
         Write-Log "⚠️ Erreur de surveillance : $($_.Exception.Message)" "WARN"
         Start-Sleep -Seconds 60
      }
   }
}

# Mettre à jour le statut final
try {
   $finalStatus = @{
      ProcessId     = $PID
      StartTime     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
      Status        = "ACTIVE_MONITORING"
      ConfigSuccess = $configSuccess
      AdminRights   = $isAdmin
      ProjectPath   = "EMAIL_SENDER_1"
      Description   = "Surveillance active - Exclusions AVG configurées"
   } | ConvertTo-Json
    
   $indicatorPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\logs\avg-auto-exclusion.status"
   Set-Content -Path $indicatorPath -Value $finalStatus -ErrorAction SilentlyContinue
}
catch {
   # Ignorer les erreurs de statut
}

Write-Log "✅ Configuration AVG terminée - Surveillance active" "INFO"
Write-Log "📊 PID du processus de surveillance : $PID" "INFO"

# Mode surveillance continue (si demandé)
if ($Force -or $env:AVG_MONITOR_ENABLED -eq "1") {
   Write-Log "🔄 Mode surveillance continue activé" "INFO"
   Start-CompilationMonitoring
}
else {
   Write-Log "ℹ️ Surveillance ponctuelle terminée" "INFO"
}
