#Requires -Version 5.1
<#
.SYNOPSIS
    Exemple d'utilisation du module Format-Converters pour la détection de format.

.DESCRIPTION
    Ce script montre comment utiliser le module Format-Converters pour détecter le format
    d'un fichier, gérer les cas ambigus, et afficher les résultats.

.PARAMETER FilePath
    Le chemin du fichier à analyser. Si non spécifié, l'utilisateur sera invité à sélectionner un fichier.

.PARAMETER AutoResolve
    Indique si les cas ambigus doivent être résolus automatiquement sans intervention de l'utilisateur.

.PARAMETER GenerateReport
    Indique si un rapport HTML doit être généré.

.EXAMPLE
    .\Example-FormatDetection.ps1
    Exécute l'exemple avec sélection de fichier interactive.

.EXAMPLE
    .\Example-FormatDetection.ps1 -FilePath "C:\path\to\file.txt"
    Exécute l'exemple avec le fichier spécifié.

.EXAMPLE
    .\Example-FormatDetection.ps1 -FilePath "C:\path\to\file.txt" -AutoResolve -GenerateReport
    Exécute l'exemple avec résolution automatique des cas ambigus et génération d'un rapport.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$FilePath,
    
    [Parameter(Mandatory = $false)]
    [switch]$AutoResolve,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# Importer le module Format-Converters
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Format-Converters.psm1"

if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Le module Format-Converters n'a pas été trouvé : $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Si aucun fichier n'est spécifié, demander à l'utilisateur d'en sélectionner un
if (-not $FilePath) {
    Add-Type -AssemblyName System.Windows.Forms
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = "Sélectionner un fichier à analyser"
    $openFileDialog.Filter = "Tous les fichiers (*.*)|*.*"
    
    if ($openFileDialog.ShowDialog() -eq "OK") {
        $FilePath = $openFileDialog.FileName
    }
    else {
        Write-Error "Aucun fichier sélectionné."
        exit 1
    }
}

# Vérifier si le fichier existe
if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
    Write-Error "Le fichier '$FilePath' n'existe pas."
    exit 1
}

Write-Host "Analyse du fichier : $FilePath" -ForegroundColor Cyan
Write-Host ""

try {
    # Détecter le format du fichier
    $detectionParams = @{
        FilePath = $FilePath
        AutoResolve = $AutoResolve
        ShowDetails = $true
        RememberChoices = $true
    }
    
    if ($GenerateReport) {
        $detectionParams.ExportResults = $true
        $detectionParams.ExportFormat = "HTML"
    }
    
    $result = Detect-FileFormat @detectionParams
    
    # Afficher un résumé
    Write-Host ""
    Write-Host "Résumé :" -ForegroundColor Green
    Write-Host "  Fichier : $FilePath" -ForegroundColor White
    Write-Host "  Format détecté : $($result.DetectedFormat)" -ForegroundColor White
    Write-Host "  Score de confiance : $($result.ConfidenceScore)%" -ForegroundColor White
    
    if ($GenerateReport) {
        $reportPath = [System.IO.Path]::ChangeExtension($FilePath, "detection.html")
        Write-Host "  Rapport généré : $reportPath" -ForegroundColor White
    }
}
catch {
    Write-Error "Une erreur s'est produite lors de la détection du format : $_"
    exit 1
}
