#Requires -Version 5.1
<#
.SYNOPSIS
    Exemple d'utilisation du module Format-Converters pour la dÃ©tection de format.

.DESCRIPTION
    Ce script montre comment utiliser le module Format-Converters pour dÃ©tecter le format
    d'un fichier, gÃ©rer les cas ambigus, et afficher les rÃ©sultats.

.PARAMETER FilePath
    Le chemin du fichier Ã  analyser. Si non spÃ©cifiÃ©, l'utilisateur sera invitÃ© Ã  sÃ©lectionner un fichier.

.PARAMETER AutoResolve
    Indique si les cas ambigus doivent Ãªtre rÃ©solus automatiquement sans intervention de l'utilisateur.

.PARAMETER GenerateReport
    Indique si un rapport HTML doit Ãªtre gÃ©nÃ©rÃ©.

.EXAMPLE
    .\Example-FormatDetection.ps1
    ExÃ©cute l'exemple avec sÃ©lection de fichier interactive.

.EXAMPLE
    .\Example-FormatDetection.ps1 -FilePath "C:\path\to\file.txt"
    ExÃ©cute l'exemple avec le fichier spÃ©cifiÃ©.

.EXAMPLE
    .\Example-FormatDetection.ps1 -FilePath "C:\path\to\file.txt" -AutoResolve -GenerateReport
    ExÃ©cute l'exemple avec rÃ©solution automatique des cas ambigus et gÃ©nÃ©ration d'un rapport.

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
    Write-Error "Le module Format-Converters n'a pas Ã©tÃ© trouvÃ© : $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Si aucun fichier n'est spÃ©cifiÃ©, demander Ã  l'utilisateur d'en sÃ©lectionner un
if (-not $FilePath) {
    Add-Type -AssemblyName System.Windows.Forms
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = "SÃ©lectionner un fichier Ã  analyser"
    $openFileDialog.Filter = "Tous les fichiers (*.*)|*.*"
    
    if ($openFileDialog.ShowDialog() -eq "OK") {
        $FilePath = $openFileDialog.FileName
    }
    else {
        Write-Error "Aucun fichier sÃ©lectionnÃ©."
        exit 1
    }
}

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
    Write-Error "Le fichier '$FilePath' n'existe pas."
    exit 1
}

Write-Host "Analyse du fichier : $FilePath" -ForegroundColor Cyan
Write-Host ""

try {
    # DÃ©tecter le format du fichier
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
    
    # Afficher un rÃ©sumÃ©
    Write-Host ""
    Write-Host "RÃ©sumÃ© :" -ForegroundColor Green
    Write-Host "  Fichier : $FilePath" -ForegroundColor White
    Write-Host "  Format dÃ©tectÃ© : $($result.DetectedFormat)" -ForegroundColor White
    Write-Host "  Score de confiance : $($result.ConfidenceScore)%" -ForegroundColor White
    
    if ($GenerateReport) {
        $reportPath = [System.IO.Path]::ChangeExtension($FilePath, "detection.html")
        Write-Host "  Rapport gÃ©nÃ©rÃ© : $reportPath" -ForegroundColor White
    }
}
catch {
    Write-Error "Une erreur s'est produite lors de la dÃ©tection du format : $_"
    exit 1
}
