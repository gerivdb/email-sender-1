<#
.SYNOPSIS
    Ajoute la gestion d'erreurs à plusieurs scripts PowerShell.

.DESCRIPTION
    Ce script ajoute automatiquement des blocs try/catch à plusieurs scripts PowerShell.
    Il utilise le module ErrorHandling pour ajouter la gestion d'erreurs.

.PARAMETER ScriptPath
    Chemin du répertoire contenant les scripts à traiter. Par défaut, utilise le répertoire courant.

.PARAMETER Filter
    Filtre pour sélectionner les scripts à traiter. Par défaut, traite tous les fichiers .ps1.

.PARAMETER Recurse
    Si spécifié, traite également les sous-répertoires.

.PARAMETER BackupFiles
    Si spécifié, crée une sauvegarde des fichiers avant de les modifier.

.PARAMETER Force
    Si spécifié, remplace les blocs try/catch existants.

.PARAMETER LogPath
    Chemin où enregistrer les journaux. Par défaut, utilise le répertoire temporaire.

.EXAMPLE
    .\Add-ErrorHandlingToScripts.ps1 -ScriptPath "D:\Projets\Scripts" -Recurse -BackupFiles
    Ajoute la gestion d'erreurs à tous les scripts PowerShell dans le répertoire spécifié et ses sous-répertoires,
    en créant des sauvegardes des fichiers avant de les modifier.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
    Prérequis:      Module ErrorHandling
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ScriptPath = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [string]$Filter = "*.ps1",

    [Parameter(Mandatory = $false)]
    [switch]$Recurse,

    [Parameter(Mandatory = $false)]
    [switch]$BackupFiles,

    [Parameter(Mandatory = $false)]
    [string]$LogPath = (Join-Path -Path $env:TEMP -ChildPath "ErrorHandlingLogs")
)

# Importer les fonctions de gestion d'erreurs
$errorHandlingScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "SimpleErrorHandling.ps1"
if (-not (Test-Path -Path $errorHandlingScriptPath)) {
    Write-Error "Script de gestion d'erreurs non trouvé: $errorHandlingScriptPath"
    exit 1
}
. $errorHandlingScriptPath

# Initialiser le module
Initialize-ErrorHandling -LogPath $LogPath

# Fonction pour traiter un script
function Start-ScriptProcessing {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )

    try {
        Write-Host "Traitement du script: $ScriptPath"

        # Vérifier si le script est valide
        Get-Content -Path $ScriptPath -Raw -ErrorAction Stop | Out-Null

        # Ajouter des blocs try/catch
        $result = Add-TryCatchBlock -ScriptPath $ScriptPath -BackupFile:$BackupFiles

        if ($result) {
            Write-Host "  Blocs try/catch ajoutés avec succès" -ForegroundColor Green
        }
        else {
            Write-Host "  Le script contient déjà des blocs try/catch" -ForegroundColor Yellow
        }

        return $true
    }
    catch {
        Write-Error "Erreur lors du traitement du script $ScriptPath : $_"
        Write-Log-Error -ErrorRecord $_ -FunctionName "Process-Script" -Category "FileSystem"
        return $false
    }
}

# Fonction principale
function Main {
    Write-Host "Ajout de la gestion d'erreurs aux scripts PowerShell"
    Write-Host "Répertoire: $ScriptPath"
    Write-Host "Filtre: $Filter"
    Write-Host "Récursif: $Recurse"
    Write-Host "Sauvegarde: $BackupFiles"
    Write-Host "Journaux: $LogPath"
    Write-Host

    # Récupérer les scripts à traiter
    $scriptParams = @{
        Path = $ScriptPath
        Filter = $Filter
        File = $true
    }

    if ($Recurse) {
        $scriptParams.Add("Recurse", $true)
    }

    $scripts = Get-ChildItem @scriptParams

    if ($scripts.Count -eq 0) {
        Write-Warning "Aucun script trouvé avec les critères spécifiés."
        return
    }

    Write-Host "Nombre de scripts à traiter: $($scripts.Count)"
    Write-Host

    # Traiter chaque script
    $successCount = 0
    $errorCount = 0

    foreach ($script in $scripts) {
        # Ignorer le script de gestion d'erreurs lui-même
        if ($script.FullName -eq $errorHandlingScriptPath -or $script.FullName -eq $PSCommandPath) {
            Write-Host "  Ignoré: $($script.FullName)" -ForegroundColor Yellow
            continue
        }

        $result = Start-ScriptProcessing -ScriptPath $script.FullName

        if ($result) {
            $successCount++
        }
        else {
            $errorCount++
        }
    }

    Write-Host
    Write-Host "Traitement terminé"
    Write-Host "Scripts traités avec succès: $successCount"
    Write-Host "Scripts avec erreurs: $errorCount"

    # Afficher le chemin des journaux
    Write-Host
    Write-Host "Les erreurs sont journalisées dans: $LogPath"
}

# Exécuter le script
Main
