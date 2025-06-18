# Script wrapper invisible pour l'auto-exclusion AVG
# Exécuté automatiquement à l'ouverture de VS Code
# Version optimisée pour une exécution en arrière-plan

param(
   [string]$Action = "auto",
   [switch]$Background = $false,
   [string]$Profile = "development"
)

# Configuration pour exécution invisible
$ProgressPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue' 
$WarningPreference = 'SilentlyContinue'
$ErrorActionPreference = 'SilentlyContinue'

# Définir le titre du processus pour identification
$Host.UI.RawUI.WindowTitle = "AVG-Auto-Exclusion-Wrapper [PID:$PID] [$Profile]"

# Chemin du projet
$ProjectPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$ScriptPath = "$ProjectPath\scripts\auto-avg-exclusion.ps1"
$LogPath = "$ProjectPath\logs\avg-wrapper.log"

# Fonction de logging
function Write-WrapperLog {
   param($Message)
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $logEntry = "[$timestamp] [WRAPPER] $Message"
    
   # Créer le répertoire de logs s'il n'existe pas
   $logDir = Split-Path $LogPath -Parent
   if (!(Test-Path $logDir)) {
      New-Item -ItemType Directory -Path $logDir -Force | Out-Null
   }
    
   Add-Content -Path $LogPath -Value $logEntry -ErrorAction SilentlyContinue
}

Write-WrapperLog "🚀 Démarrage du wrapper AVG - Action: $Action, Background: $Background, Profile: $Profile"

# Vérifier si le script principal existe
if (!(Test-Path $ScriptPath)) {
   Write-WrapperLog "❌ Script principal non trouvé : $ScriptPath"
   exit 1
}

# Fonction pour démarrer le script en arrière-plan
function Start-BackgroundScript {
   try {
      Write-WrapperLog "🔄 Démarrage du script en arrière-plan..."
        
      # Utiliser Start-Process pour créer un processus détaché
      $processArgs = @{
         FilePath     = "powershell.exe"
         ArgumentList = @(
            "-WindowStyle", "Hidden",
            "-ExecutionPolicy", "Bypass",
            "-File", $ScriptPath,
            "-Silent",
            "-Force"
         )
         WindowStyle  = "Hidden"
         PassThru     = $true
      }
        
      $process = Start-Process @processArgs
      
      # Démarrer également le script d'exclusion spécifique pour .exe
      $exeScriptPath = "$ProjectPath\scripts\ensure-exe-exclusion.ps1"
      if (Test-Path $exeScriptPath) {
         Write-WrapperLog "🔄 Démarrage du script d'exclusion .exe..."
         
         $exeProcessArgs = @{
            FilePath     = "powershell.exe"
            ArgumentList = @(
               "-WindowStyle", "Hidden",
               "-ExecutionPolicy", "Bypass",
               "-File", $exeScriptPath,
               "-Silent"
            )
            WindowStyle  = "Hidden"
         }
         
         Start-Process @exeProcessArgs | Out-Null
         Write-WrapperLog "✅ Script d'exclusion .exe lancé"
      }
        
      if ($process) {
         Write-WrapperLog "✅ Processus lancé avec succès - PID: $($process.Id)"
            
         # Créer un fichier de suivi du processus
         $processInfo = @{
            WrapperPID    = $PID
            BackgroundPID = $process.Id
            StartTime     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            Action        = $Action
            Profile       = $Profile
            Status        = "RUNNING"
         } | ConvertTo-Json
            
         $processFile = "$ProjectPath\logs\avg-background-process.json"
         Set-Content -Path $processFile -Value $processInfo -ErrorAction SilentlyContinue
            
         return $process.Id
      }
      else {
         Write-WrapperLog "❌ Échec du lancement du processus"
         return $null
      }
   }
   catch {
      Write-WrapperLog "❌ Erreur lors du lancement : $($_.Exception.Message)"
      return $null
   }
}

# Fonction pour exécuter en mode synchrone (pour tests)
function Start-SyncScript {
   try {
      Write-WrapperLog "⚡ Exécution synchrone du script..."
        
      & $ScriptPath -Silent
        
      Write-WrapperLog "✅ Exécution synchrone terminée"
      return $true
   }
   catch {
      Write-WrapperLog "❌ Erreur en mode synchrone : $($_.Exception.Message)"
      return $false
   }
}

# Fonction pour vérifier l'état des processus existants
function Get-ExistingProcesses {
   try {
      $processFile = "$ProjectPath\logs\avg-background-process.json"
        
      if (Test-Path $processFile) {
         $processInfo = Get-Content $processFile | ConvertFrom-Json
            
         # Vérifier si le processus est encore actif
         $process = Get-Process -Id $processInfo.BackgroundPID -ErrorAction SilentlyContinue
            
         if ($process) {
            Write-WrapperLog "ℹ️ Processus existant détecté (PID: $($processInfo.BackgroundPID))"
            return $processInfo.BackgroundPID
         }
         else {
            Write-WrapperLog "🧹 Nettoyage de l'ancien fichier de processus"
            Remove-Item $processFile -ErrorAction SilentlyContinue
         }
      }
        
      return $null
   }
   catch {
      Write-WrapperLog "⚠️ Erreur lors de la vérification des processus : $($_.Exception.Message)"
      return $null
   }
}

# Logique principale basée sur l'action
switch ($Action.ToLower()) {
   "auto" {
      Write-WrapperLog "🤖 Mode AUTO - Démarrage automatique"
        
      # Vérifier s'il y a déjà un processus en cours
      $existingPID = Get-ExistingProcesses
        
      if ($existingPID) {
         Write-WrapperLog "✅ Processus de surveillance déjà actif (PID: $existingPID)"
      }
      else {
         # Démarrer un nouveau processus en arrière-plan
         $newPID = Start-BackgroundScript
            
         if ($newPID) {
            Write-WrapperLog "🎉 Nouveau processus de surveillance démarré (PID: $newPID)"
         }
         else {
            Write-WrapperLog "💥 Échec du démarrage - Tentative en mode synchrone"
            Start-SyncScript
         }
      }
   }
    
   "start" {
      Write-WrapperLog "▶️ Mode START - Démarrage forcé"
      $newPID = Start-BackgroundScript
        
      if ($newPID) {
         Write-WrapperLog "✅ Processus démarré (PID: $newPID)"
      }
   }
    
   "stop" {
      Write-WrapperLog "⏹️ Mode STOP - Arrêt des processus"
        
      $processFile = "$ProjectPath\logs\avg-background-process.json"
        
      if (Test-Path $processFile) {
         try {
            $processInfo = Get-Content $processFile | ConvertFrom-Json
            $process = Get-Process -Id $processInfo.BackgroundPID -ErrorAction SilentlyContinue
                
            if ($process) {
               Stop-Process -Id $processInfo.BackgroundPID -Force -ErrorAction SilentlyContinue
               Write-WrapperLog "🛑 Processus arrêté (PID: $($processInfo.BackgroundPID))"
            }
                
            Remove-Item $processFile -ErrorAction SilentlyContinue
         }
         catch {
            Write-WrapperLog "⚠️ Erreur lors de l'arrêt : $($_.Exception.Message)"
         }
      }
      else {
         Write-WrapperLog "ℹ️ Aucun processus en cours détecté"
      }
   }
    
   "status" {
      Write-WrapperLog "📊 Mode STATUS - Vérification de l'état"
        
      $existingPID = Get-ExistingProcesses
        
      if ($existingPID) {
         Write-WrapperLog "✅ Processus actif détecté (PID: $existingPID)"
            
         # Afficher des informations détaillées
         $process = Get-Process -Id $existingPID -ErrorAction SilentlyContinue
         if ($process) {
            Write-WrapperLog "📈 CPU: $($process.CPU), Mémoire: $($process.WorkingSet64 / 1MB) MB"
         }
      }
      else {
         Write-WrapperLog "❌ Aucun processus de surveillance actif"
      }
   }
    
   "monitor" {
      Write-WrapperLog "👀 Mode MONITOR - Surveillance interactive"
        
      # Démarrer en mode surveillance avec logs en temps réel
      $env:AVG_MONITOR_ENABLED = "1"
      Start-SyncScript
   }
    
   default {
      Write-WrapperLog "❓ Action inconnue : $Action"
      Write-WrapperLog "📋 Actions disponibles : auto, start, stop, status, monitor"
   }
}

Write-WrapperLog "🏁 Wrapper terminé - Action: $Action"

# En mode background, rester invisible
if ($Background) {
   # Ne pas afficher de sortie
   exit 0
}
