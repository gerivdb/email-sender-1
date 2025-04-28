#Requires -Version 5.1
<#
.SYNOPSIS
    Exemple d'utilisation du module Format-Converters pour l'analyse de format.

.DESCRIPTION
    Ce script montre comment utiliser le module Format-Converters pour analyser un fichier
    et obtenir des informations dÃ©taillÃ©es sur son format.

.PARAMETER FilePath
    Le chemin du fichier Ã  analyser.

.PARAMETER Format
    Le format du fichier. Si non spÃ©cifiÃ©, il sera dÃ©tectÃ© automatiquement.

.PARAMETER IncludeContent
    Indique si le contenu du fichier doit Ãªtre inclus dans l'analyse.

.PARAMETER ExportReport
    Indique si un rapport d'analyse doit Ãªtre gÃ©nÃ©rÃ©.

.EXAMPLE
    .\Analyze-FileFormat-Example.ps1 -FilePath "data.json" -ExportReport
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$FilePath,
    
    [Parameter(Mandatory = $false)]
    [string]$Format,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeContent,
    
    [Parameter(Mandatory = $false)]
    [switch]$ExportReport
)

# Importer le module Format-Converters
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Format-Converters.psm1"
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

Write-Host "Analyse du fichier : $FilePath" -ForegroundColor Cyan

try {
    # Analyser le fichier
    $analysisParams = @{
        FilePath = $FilePath
        IncludeContent = $IncludeContent
    }
    
    if ($Format) {
        $analysisParams.Format = $Format
    }
    else {
        $analysisParams.AutoDetect = $true
    }
    
    if ($ExportReport) {
        $analysisParams.ExportReport = $true
        $analysisParams.ReportPath = [System.IO.Path]::ChangeExtension($FilePath, "analysis.json")
    }
    
    $result = Analyze-FileFormat @analysisParams
    
    # Afficher les rÃ©sultats
    Write-Host "RÃ©sultats de l'analyse :" -ForegroundColor Green
    $result | Format-List
    
    if ($ExportReport) {
        Write-Host "Rapport d'analyse gÃ©nÃ©rÃ© : $($analysisParams.ReportPath)" -ForegroundColor Green
    }
}
catch {
    Write-Error "Erreur lors de l'analyse : $_"
}
