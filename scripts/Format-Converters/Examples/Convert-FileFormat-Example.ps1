#Requires -Version 5.1
<#
.SYNOPSIS
    Exemple d'utilisation du module Format-Converters pour la conversion de format.

.DESCRIPTION
    Ce script montre comment utiliser le module Format-Converters pour convertir un fichier
    d'un format à un autre.

.PARAMETER InputPath
    Le chemin du fichier d'entrée.

.PARAMETER OutputPath
    Le chemin du fichier de sortie.

.PARAMETER InputFormat
    Le format du fichier d'entrée. Si non spécifié, il sera détecté automatiquement.

.PARAMETER OutputFormat
    Le format du fichier de sortie.

.PARAMETER Force
    Indique si le fichier de sortie doit être écrasé s'il existe déjà.

.EXAMPLE
    .\Convert-FileFormat-Example.ps1 -InputPath "data.json" -OutputPath "data.xml" -OutputFormat "XML"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$InputPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [string]$InputFormat,
    
    [Parameter(Mandatory = $true)]
    [string]$OutputFormat,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Importer le module Format-Converters
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Format-Converters.psm1"
Import-Module $modulePath -Force

# Si aucun fichier d'entrée n'est spécifié, demander à l'utilisateur d'en sélectionner un
if (-not $InputPath) {
    Add-Type -AssemblyName System.Windows.Forms
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = "Sélectionner un fichier à convertir"
    $openFileDialog.Filter = "Tous les fichiers (*.*)|*.*"
    
    if ($openFileDialog.ShowDialog() -eq "OK") {
        $InputPath = $openFileDialog.FileName
    }
    else {
        Write-Error "Aucun fichier sélectionné."
        exit 1
    }
}

# Si aucun fichier de sortie n'est spécifié, générer un nom basé sur le fichier d'entrée
if (-not $OutputPath) {
    $OutputPath = [System.IO.Path]::ChangeExtension($InputPath, ".$($OutputFormat.ToLower())")
}

Write-Host "Conversion du fichier :" -ForegroundColor Cyan
Write-Host "  Entrée : $InputPath" -ForegroundColor White
Write-Host "  Sortie : $OutputPath" -ForegroundColor White
Write-Host "  Format de sortie : $OutputFormat" -ForegroundColor White

try {
    # Convertir le fichier
    $conversionParams = @{
        InputPath = $InputPath
        OutputPath = $OutputPath
        OutputFormat = $OutputFormat
        Force = $Force
        ShowProgress = $true
    }
    
    if ($InputFormat) {
        $conversionParams.InputFormat = $InputFormat
    }
    else {
        $conversionParams.AutoDetect = $true
    }
    
    $result = Convert-FileFormat @conversionParams
    
    # Afficher le résultat
    if ($result.Success) {
        Write-Host "Conversion réussie !" -ForegroundColor Green
    }
    else {
        Write-Host "Échec de la conversion : $($result.Message)" -ForegroundColor Red
    }
}
catch {
    Write-Error "Erreur lors de la conversion : $_"
}
