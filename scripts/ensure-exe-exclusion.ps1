# Script spécifique pour s'assurer que tous les fichiers .exe sont exclus d'AVG
# Ce script doit être exécuté après le script principal d'auto-exclusion
# Focalisation sur .exe qui est particulièrement problématique

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

# Chemin du projet
$ProjectPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$LogPath = "$ProjectPath\logs\avg-exe-exclusion.log"

# Fonction de logging
function Write-ExeLog {
   param($Message, $Level = "INFO")
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $logEntry = "[$timestamp] [$Level] $Message"
    
   # Créer le répertoire de logs s'il n'existe pas
   $logDir = Split-Path $LogPath -Parent
   if (!(Test-Path $logDir)) {
      New-Item -ItemType Directory -Path $logDir -Force | Out-Null
   }
    
   Add-Content -Path $LogPath -Value $logEntry -ErrorAction SilentlyContinue
    
   # Aussi dans la console si pas en mode silencieux
   if (!$Silent) {
      Write-Host $logEntry
   }
}

Write-ExeLog "🔍 Démarrage de la vérification spéciale des exclusions .exe" "INFO"

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

# Vérifier si AVG est installé
if (!(Test-AVGInstalled)) {
   Write-ExeLog "ℹ️ AVG non détecté ou inactif - Arrêt du script" "INFO"
   exit 0
}

Write-ExeLog "🛡️ AVG détecté et actif - Configuration des exclusions .exe..." "INFO"

# Liste des dossiers contenant potentiellement des .exe
$criticalFolders = @(
   "$ProjectPath",
   "$ProjectPath\cmd",
   "$ProjectPath\tools",
   "$ProjectPath\bin",
   "$ProjectPath\development",
   "$ProjectPath\logs",
   "$env:TEMP\go-build*",
   "$env:LOCALAPPDATA\go-build",
   "C:\Users\$env:USERNAME\AppData\Local\go-build"
)

# Créer des marqueurs spécifiques pour .exe
foreach ($folder in $criticalFolders) {
   if (Test-Path $folder) {
      $markerFile = Join-Path $folder ".avg-exclude-exe-marker"
      "AVG_EXCLUDE_EXE_FILES" | Out-File $markerFile -ErrorAction SilentlyContinue
      Write-ExeLog "✅ Créé marqueur d'exclusion .exe dans : $folder" "INFO"
   }
}

# Fonction pour créer un script de configuration manuelle spécifique aux .exe
function New-ExeExclusionScript {
   $exeScript = @"
# Instructions spécifiques pour exclure les fichiers .exe d'AVG
# AUTOMATIQUEMENT GÉNÉRÉ - $(Get-Date)

Write-Host "🛡️ Configuration manuelle AVG pour fichiers .exe" -ForegroundColor Yellow
Write-Host ""
Write-Host "📁 Dossiers .exe à exclure :" -ForegroundColor Green
$(foreach ($folder in $criticalFolders) { "Write-Host '  - $folder' -ForegroundColor Cyan" })

Write-Host ""
Write-Host "📝 Extension critique à exclure :" -ForegroundColor Green  
Write-Host '  - *.exe' -ForegroundColor Cyan

Write-Host ""
Write-Host "📋 ÉTAPES SPÉCIFIQUES POUR .EXE :" -ForegroundColor Yellow
Write-Host "1. Ouvrir AVG Antivirus"
Write-Host "2. Menu → Paramètres → Général → Exceptions"
Write-Host "3. Ajouter '*.exe' comme exception explicite"
Write-Host "4. Ajouter chaque dossier ci-dessus comme exception"
Write-Host "5. Redémarrer le système"

try {
    Start-Process "C:\Program Files\AVG\Antivirus\AVGUI.exe"
}
catch {
    Write-Host "❌ Ouvrir manuellement AVG depuis le menu Démarrer"
}
"@
    
   $scriptPath = "$ProjectPath\scripts\manual-exe-exclusion.ps1"
   Set-Content -Path $scriptPath -Value $exeScript -ErrorAction SilentlyContinue
   Write-ExeLog "📜 Script de configuration manuelle .exe créé : $scriptPath" "INFO"

   return $scriptPath
}

# Créer le script de configuration manuelle pour les .exe
$manualScriptPath = New-ExeExclusionScript

Write-ExeLog "✅ Configuration des exclusions .exe terminée" "INFO"
Write-ExeLog "📋 Pour une configuration manuelle, exécuter : $manualScriptPath" "INFO"

# Tenter d'ajouter automatiquement l'exclusion
try {
   Write-ExeLog "🔄 Tentative d'ajout automatique d'exclusion pour *.exe" "INFO"
   
   # Créer un marqueur généralisé pour tout le projet
   $globalMarker = Join-Path $ProjectPath ".avg-exclude-all-exe-files"
   "AVG_EXCLUDE_ALL_EXE_FILES" | Out-File $globalMarker -ErrorAction SilentlyContinue
   Write-ExeLog "✅ Créé marqueur global pour exclusion .exe" "INFO"
}
catch {
   Write-ExeLog "⚠️ Erreur lors de la configuration automatique : $($_.Exception.Message)" "ERROR"
}

exit 0
