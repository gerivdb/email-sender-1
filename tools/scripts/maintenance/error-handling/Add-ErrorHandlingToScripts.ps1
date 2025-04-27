<#
.SYNOPSIS
    Ajoute la gestion d'erreurs Ã  plusieurs scripts PowerShell.

.DESCRIPTION
    Ce script ajoute automatiquement des blocs try/catch Ã  plusieurs scripts PowerShell.
    Il utilise le module ErrorHandling pour ajouter la gestion d'erreurs.

.PARAMETER ScriptPath
    Chemin du rÃ©pertoire contenant les scripts Ã  traiter. Par dÃ©faut, utilise le rÃ©pertoire courant.

.PARAMETER Filter
    Filtre pour sÃ©lectionner les scripts Ã  traiter. Par dÃ©faut, traite tous les fichiers .ps1.

.PARAMETER Recurse
    Si spÃ©cifiÃ©, traite Ã©galement les sous-rÃ©pertoires.

.PARAMETER BackupFiles
    Si spÃ©cifiÃ©, crÃ©e une sauvegarde des fichiers avant de les modifier.

.PARAMETER Force
    Si spÃ©cifiÃ©, remplace les blocs try/catch existants.

.PARAMETER LogPath
    Chemin oÃ¹ enregistrer les journaux. Par dÃ©faut, utilise le rÃ©pertoire temporaire.

.EXAMPLE
    .\Add-ErrorHandlingToScripts.ps1 -ScriptPath "D:\Projets\Scripts" -Recurse -BackupFiles
    Ajoute la gestion d'erreurs Ã  tous les scripts PowerShell dans le rÃ©pertoire spÃ©cifiÃ© et ses sous-rÃ©pertoires,
    en crÃ©ant des sauvegardes des fichiers avant de les modifier.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
    PrÃ©requis:      Module ErrorHandling
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
    Write-Error "Script de gestion d'erreurs non trouvÃ©: $errorHandlingScriptPath"
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

        # VÃ©rifier si le script est valide
        Get-Content -Path $ScriptPath -Raw -ErrorAction Stop | Out-Null

        # Ajouter des blocs try/catch
        $result = Add-TryCatchBlock -ScriptPath $ScriptPath -BackupFile:$BackupFiles

        if ($result) {
            Write-Host "  Blocs try/catch ajoutÃ©s avec succÃ¨s" -ForegroundColor Green
        }
        else {
            Write-Host "  Le script contient dÃ©jÃ  des blocs try/catch" -ForegroundColor Yellow
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
    Write-Host "RÃ©pertoire: $ScriptPath"
    Write-Host "Filtre: $Filter"
    Write-Host "RÃ©cursif: $Recurse"
    Write-Host "Sauvegarde: $BackupFiles"
    Write-Host "Journaux: $LogPath"
    Write-Host

    # RÃ©cupÃ©rer les scripts Ã  traiter
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
        Write-Warning "Aucun script trouvÃ© avec les critÃ¨res spÃ©cifiÃ©s."
        return
    }

    Write-Host "Nombre de scripts Ã  traiter: $($scripts.Count)"
    Write-Host

    # Traiter chaque script
    $successCount = 0
    $errorCount = 0

    foreach ($script in $scripts) {
        # Ignorer le script de gestion d'erreurs lui-mÃªme
        if ($script.FullName -eq $errorHandlingScriptPath -or $script.FullName -eq $PSCommandPath) {
            Write-Host "  IgnorÃ©: $($script.FullName)" -ForegroundColor Yellow
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
    Write-Host "Traitement terminÃ©"
    Write-Host "Scripts traitÃ©s avec succÃ¨s: $successCount"
    Write-Host "Scripts avec erreurs: $errorCount"

    # Afficher le chemin des journaux
    Write-Host
    Write-Host "Les erreurs sont journalisÃ©es dans: $LogPath"
}

# ExÃ©cuter le script
Main
