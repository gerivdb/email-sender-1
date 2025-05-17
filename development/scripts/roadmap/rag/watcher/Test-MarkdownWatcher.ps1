#Requires -Version 5.1
<#
.SYNOPSIS
    Teste le système de détection des modifications en temps réel des fichiers Markdown.
.DESCRIPTION
    Ce script teste le système de détection des modifications en temps réel des fichiers
    Markdown en créant un fichier temporaire et en simulant des modifications.
.PARAMETER TestDirectory
    Répertoire où créer les fichiers de test. Par défaut, utilise un répertoire temporaire.
.PARAMETER Duration
    Durée du test en secondes. Par défaut, 60 secondes.
.PARAMETER ModificationInterval
    Intervalle entre les modifications en secondes. Par défaut, 5 secondes.
.EXAMPLE
    .\Test-MarkdownWatcher.ps1 -Duration 120 -ModificationInterval 10
    Exécute le test pendant 120 secondes avec des modifications toutes les 10 secondes.
.NOTES
    Nom: Test-MarkdownWatcher.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-06-10
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$TestDirectory = "",
    
    [Parameter(Mandatory = $false)]
    [int]$Duration = 60,
    
    [Parameter(Mandatory = $false)]
    [int]$ModificationInterval = 5
)

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesPath = Join-Path -Path $scriptPath -ChildPath "..\modules"
$loggingModulePath = Join-Path -Path $modulesPath -ChildPath "Logging.psm1"

if (Test-Path -Path $loggingModulePath) {
    Import-Module $loggingModulePath -Force
} else {
    # Fonction de logging simplifiée si le module n'est pas disponible
    function Write-Log {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Message,
            
            [Parameter(Mandatory = $false)]
            [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "DEBUG")]
            [string]$Level = "INFO"
        )
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] [$Level] $Message"
        
        # Définir la couleur en fonction du niveau
        $color = switch ($Level) {
            "INFO" { "White" }
            "WARNING" { "Yellow" }
            "ERROR" { "Red" }
            "SUCCESS" { "Green" }
            "DEBUG" { "Cyan" }
            default { "White" }
        }
        
        # Afficher le message dans la console
        Write-Host $logMessage -ForegroundColor $color
    }
}

# Fonction pour créer un fichier Markdown de test
function New-TestMarkdownFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    $content = @"
# Plan de test
*Version 1.0 - $(Get-Date -Format "yyyy-MM-dd") - Progression globale : 0%*

Ce fichier est utilisé pour tester le système de détection des modifications en temps réel.

## 1. Section de test

- [ ] **1.1** Tâche de test 1
  - [ ] **1.1.1** Sous-tâche de test 1.1
  - [ ] **1.1.2** Sous-tâche de test 1.2
- [ ] **1.2** Tâche de test 2
  - [ ] **1.2.1** Sous-tâche de test 2.1
  - [ ] **1.2.2** Sous-tâche de test 2.2

## 2. Autre section de test

- [ ] **2.1** Tâche de test 3
  - [ ] **2.1.1** Sous-tâche de test 3.1
  - [ ] **2.1.2** Sous-tâche de test 3.2
- [ ] **2.2** Tâche de test 4
  - [ ] **2.2.1** Sous-tâche de test 4.1
  - [ ] **2.2.2** Sous-tâche de test 4.2
"@
    
    $content | Set-Content -Path $FilePath -Encoding UTF8
    
    Write-Log "Fichier de test créé: $FilePath" -Level "SUCCESS"
}

# Fonction pour modifier un fichier Markdown de test
function Update-TestMarkdownFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [int]$ModificationNumber
    )
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw
    
    # Effectuer différentes modifications en fonction du numéro
    switch ($ModificationNumber % 5) {
        0 {
            # Ajouter une nouvelle tâche
            $newTask = "`n- [ ] **3.1** Nouvelle tâche $ModificationNumber"
            $content = $content + $newTask
            Write-Log "Ajout d'une nouvelle tâche" -Level "INFO"
        }
        1 {
            # Modifier le statut d'une tâche existante
            $content = $content -replace "- \[ \] \*\*1\.1\*\*", "- [x] **1.1**"
            Write-Log "Modification du statut d'une tâche" -Level "INFO"
        }
        2 {
            # Modifier le titre d'une tâche existante
            $content = $content -replace "Tâche de test 2", "Tâche de test 2 modifiée $ModificationNumber"
            Write-Log "Modification du titre d'une tâche" -Level "INFO"
        }
        3 {
            # Supprimer une tâche existante
            $content = $content -replace "- \[ \] \*\*2\.2\*\*.*\r?\n  - \[ \] \*\*2\.2\.1\*\*.*\r?\n  - \[ \] \*\*2\.2\.2\*\*.*\r?\n", ""
            Write-Log "Suppression d'une tâche" -Level "INFO"
        }
        4 {
            # Modifier la progression globale
            $content = $content -replace "Progression globale : \d+%", "Progression globale : $($ModificationNumber * 5)%"
            Write-Log "Modification de la progression globale" -Level "INFO"
        }
    }
    
    # Enregistrer le contenu modifié
    $content | Set-Content -Path $FilePath -Encoding UTF8
    
    Write-Log "Fichier de test modifié: $FilePath" -Level "SUCCESS"
}

# Fonction pour démarrer le watcher
function Start-Watcher {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WatchPath
    )
    
    $watcherScriptPath = Join-Path -Path $scriptPath -ChildPath "Watch-MarkdownFiles.ps1"
    
    if (-not (Test-Path -Path $watcherScriptPath)) {
        Write-Log "Le script de surveillance n'existe pas: $watcherScriptPath" -Level "ERROR"
        return $null
    }
    
    # Démarrer le watcher dans un nouveau processus
    $process = Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$watcherScriptPath`" -WatchPath `"$WatchPath`" -EnableVerboseLogging" -PassThru -WindowStyle Normal
    
    Write-Log "Watcher démarré avec PID: $($process.Id)" -Level "SUCCESS"
    
    return $process
}

# Fonction principale
function Test-Watcher {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$TestDirectory = "",
        
        [Parameter(Mandatory = $false)]
        [int]$Duration = 60,
        
        [Parameter(Mandatory = $false)]
        [int]$ModificationInterval = 5
    )
    
    try {
        # Créer un répertoire temporaire si non spécifié
        if (-not $TestDirectory) {
            $TestDirectory = Join-Path -Path $env:TEMP -ChildPath "MarkdownWatcherTest_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        }
        
        # Créer le répertoire s'il n'existe pas
        if (-not (Test-Path -Path $TestDirectory)) {
            New-Item -ItemType Directory -Path $TestDirectory -Force | Out-Null
        }
        
        Write-Log "Répertoire de test: $TestDirectory" -Level "INFO"
        
        # Créer un fichier Markdown de test
        $testFilePath = Join-Path -Path $TestDirectory -ChildPath "test_plan.md"
        New-TestMarkdownFile -FilePath $testFilePath
        
        # Démarrer le watcher
        $watcherProcess = Start-Watcher -WatchPath $TestDirectory
        
        if (-not $watcherProcess) {
            Write-Log "Impossible de démarrer le watcher" -Level "ERROR"
            return
        }
        
        # Attendre que le watcher soit prêt
        Start-Sleep -Seconds 5
        
        # Effectuer des modifications à intervalles réguliers
        $startTime = Get-Date
        $modificationCount = 0
        
        while ((Get-Date) -lt $startTime.AddSeconds($Duration)) {
            # Effectuer une modification
            Update-TestMarkdownFile -FilePath $testFilePath -ModificationNumber $modificationCount
            $modificationCount++
            
            # Attendre l'intervalle spécifié
            Start-Sleep -Seconds $ModificationInterval
        }
        
        # Arrêter le watcher
        Stop-Process -Id $watcherProcess.Id -Force
        
        Write-Log "Test terminé. $modificationCount modifications effectuées." -Level "SUCCESS"
        
        # Afficher les logs récents
        Write-Log "Logs récents:" -Level "INFO"
        Get-RecentLogs -Count 20 | ForEach-Object { Write-Host $_ }
    } catch {
        Write-Log "Erreur lors du test: $_" -Level "ERROR"
        
        # Arrêter le watcher si nécessaire
        if ($watcherProcess -and -not $watcherProcess.HasExited) {
            Stop-Process -Id $watcherProcess.Id -Force
        }
    }
}

# Exécuter la fonction principale avec les paramètres fournis
Test-Watcher -TestDirectory $TestDirectory -Duration $Duration -ModificationInterval $ModificationInterval
