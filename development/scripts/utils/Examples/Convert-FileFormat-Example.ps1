#Requires -Version 5.1
<#
.SYNOPSIS
    Exemple d'utilisation du module Format-Converters pour la conversion de format.

.DESCRIPTION
    Ce script montre comment utiliser le module Format-Converters pour convertir un fichier
    d'un format Ã  un autre.

.PARAMETER InputPath
    Le chemin du fichier d'entrÃ©e.

.PARAMETER OutputPath
    Le chemin du fichier de sortie.

.PARAMETER InputFormat
    Le format du fichier d'entrÃ©e. Si non spÃ©cifiÃ©, il sera dÃ©tectÃ© automatiquement.

.PARAMETER OutputFormat
    Le format du fichier de sortie.

.PARAMETER Force
    Indique si le fichier de sortie doit Ãªtre Ã©crasÃ© s'il existe dÃ©jÃ .

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

# Si aucun fichier d'entrÃ©e n'est spÃ©cifiÃ©, demander Ã  l'utilisateur d'en sÃ©lectionner un
if (-not $InputPath) {
    Add-Type -AssemblyName System.Windows.Forms
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = "SÃ©lectionner un fichier Ã  convertir"
    $openFileDialog.Filter = "Tous les fichiers (*.*)|*.*"
    
    if ($openFileDialog.ShowDialog() -eq "OK") {
        $InputPath = $openFileDialog.FileName
    }
    else {
        Write-Error "Aucun fichier sÃ©lectionnÃ©."
        exit 1
    }
}

# Si aucun fichier de sortie n'est spÃ©cifiÃ©, gÃ©nÃ©rer un nom basÃ© sur le fichier d'entrÃ©e
if (-not $OutputPath) {
    $OutputPath = [System.IO.Path]::ChangeExtension($InputPath, ".$($OutputFormat.ToLower())")
}

Write-Host "Conversion du fichier :" -ForegroundColor Cyan
Write-Host "  EntrÃ©e : $InputPath" -ForegroundColor White
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
    
    # Afficher le rÃ©sultat
    if ($result.Success) {
        Write-Host "Conversion rÃ©ussie !" -ForegroundColor Green
    }
    else {
        Write-Host "Ã‰chec de la conversion : $($result.Message)" -ForegroundColor Red
    }
}
catch {
    Write-Error "Erreur lors de la conversion : $_"
}
