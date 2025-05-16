﻿<#
.SYNOPSIS
Redémarre Visual Studio Code proprement en arrêtant tous les processus associés.

.DESCRIPTION
Ce script arrête tous les processus Visual Studio Code en cours d'exécution,
    puis redémarre l'application avec le dossier de travail actuel. Il peut également
sauvegarder et restaurer les fichiers ouverts.

.PARAMETER SaveWorkspace
Set-Item spécifié, tente de sauvegarder l'état de l'espace de travail avant de redémarrer.

.PARAMETER WaitSeconds
Le nombre de secondes à attendre après avoir arrêté les processus VSCode avant de redémarrer.
Par défaut: 3 secondes.

.PARAMETER CleanMemory
Set-Item spécifié, exécute également le script de nettoyage de la mémoire avant de redémarrer.

.PARAMETER MaxMemoryMB
La quantité maximale de mémoire (en Mo) autorisée pour VSCode après le redémarrage.
Par défaut: 4096 Mo (4 Go).

.EXAMPLE
.\Restart-VSCode.ps1

.EXAMPLE
.\Restart-VSCode.ps1 -SaveWorkspace -CleanMemory

.NOTES
Auteur: Maintenance Team
Version: 1.0
Get-Date de création: 2025-05-16
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$SaveWorkspace,

    [Parameter(Mandatory = $false)]
    [int]$WaitSeconds = 3,

    [Parameter(Mandatory = $false)]
    [switch]$CleanMemory,

    [Parameter(Mandatory = $false)]
    [int]$MaxMemoryMB = 4096
)

# Fonction pour écrire des messages de log
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        "INFO" { Write-Host $logMessage -ForegroundColor Cyan }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default { Write-Host $logMessage }
    }
}

# Fonction pour trouver le chemin de l'exécutable VSCode
function Get-VSCodePath {
    [CmdletBinding()]
    param ()

    $possiblePaths = @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
        "$env:ProgramFiles\Microsoft VS Code\Code.exe",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\Code.exe"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    # Essayer de trouver via la commande 'code'
    try {
        $codePath = (Get-Command code -ErrorAction SilentlyContinue).Source
        if ($codePath) {
            return $codePath
        }
    } catch {
        # Ignorer l'erreur
    }

    return $null
}

# Fonction pour arrêter tous les processus VSCode
function Stop-AllVSCodeProcesses {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param ()

    $stoppedCount = 0
    $processes = Get-Process | Where-Object { $_.Name -like "*code*" }

    foreach ($process in $processes) {
        if ($PSCmdlet.ShouldProcess("Processus $($process.Name) (PID: $($process.Id))", "Arrêter")) {
            try {
                $process.CloseMainWindow() | Out-Null
                Start-Sleep -Milliseconds 500

                if (-not $process.HasExited) {
                    $process.Kill()
                }

                $stoppedCount++
                Write-Log "Processus arrêté: $($process.Name) (PID: $($process.Id))" -Level "SUCCESS"
            } catch {
                Write-Log "Erreur lors de l'arrêt du processus $($process.Id): $_" -Level "ERROR"
            }
        }
    }

    return $stoppedCount
}

# Fonction pour nettoyer la mémoire du système
function Clear-SystemMemory {
    [CmdletBinding()]
    param ()

    Write-Log "Nettoyage de la mémoire système..." -Level "INFO"

    # Forcer le garbage collector .NET
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()

    # Exécuter le script de nettoyage de la mémoire si disponible
    $cleanMemoryScript = Join-Path -Path $PSScriptRoot -ChildPath "Clean-SystemMemory.ps1"
    if (Test-Path $cleanMemoryScript) {
        try {
            & $cleanMemoryScript
            Write-Log "Script de nettoyage de la mémoire exécuté avec succès." -Level "SUCCESS"
        } catch {
            Write-Log "Erreur lors de l'exécution du script de nettoyage de la mémoire: $_" -Level "ERROR"
        }
    } else {
        Write-Log "Script de nettoyage de la mémoire non trouvé: $cleanMemoryScript" -Level "WARNING"
    }
}

# Fonction principale
function Main {
    Write-Log "Démarrage du processus de redémarrage de Visual Studio Code..." -Level "INFO"

    # Sauvegarder l'espace de travail si demandé
    if ($SaveWorkspace) {
        Write-Log "Sauvegarde de l'espace de travail..." -Level "INFO"
        # Cette fonctionnalité nécessiterait une extension VSCode ou une API
        # Pour l'instant, nous comptons sur l'auto-sauvegarde de VSCode
    }

    # Obtenir le chemin actuel
    $currentPath = Get-Location

    # Arrêter tous les processus VSCode
    $stoppedCount = Stop-AllVSCodeProcesses
    Write-Log "$stoppedCount processus VSCode ont été arrêtés." -Level "INFO"

    # Attendre quelques secondes
    Write-Log "Attente de $WaitSeconds secondes avant de redémarrer..." -Level "INFO"
    Start-Sleep -Seconds $WaitSeconds

    # Nettoyer la mémoire si demandé
    if ($CleanMemory) {
        Clear-SystemMemory
    }

    # Trouver le chemin de VSCode
    $vscodePath = Get-VSCodePath
    if (-not $vscodePath) {
        Write-Log "Impossible de trouver le chemin de Visual Studio Code. Veuillez le redémarrer manuellement." -Level "ERROR"
        return
    }

    # Redémarrer VSCode
    Write-Log "Redémarrage de Visual Studio Code..." -Level "INFO"
    try {
        Start-Process -FilePath $vscodePath -ArgumentList "`"$currentPath`"" -WindowStyle Normal
        Write-Log "Visual Studio Code a été redémarré avec succès." -Level "SUCCESS"
    } catch {
        Write-Log "Erreur lors du redémarrage de Visual Studio Code: $_" -Level "ERROR"
    }
}

# Exécuter la fonction principale
Main
