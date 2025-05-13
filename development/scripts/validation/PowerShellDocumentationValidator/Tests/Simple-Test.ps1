#Requires -Version 5.1
<#
.SYNOPSIS
    Test simple pour le module PowerShellDocumentationValidator.
.DESCRIPTION
    Ce script teste les fonctionnalités de base du module PowerShellDocumentationValidator.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

[CmdletBinding()]
param()

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\PowerShellDocumentationValidator.psm1'
Import-Module -Name $modulePath -Force

# Créer un fichier de test simple
$tempFile = Join-Path -Path $PSScriptRoot -ChildPath 'TestFile.ps1'

$fileContent = @'
<#
.SYNOPSIS
    Fonction de test.
.DESCRIPTION
    Cette fonction est utilisée pour tester le validateur de documentation.
#>
function Test-Function {
    param (
        [string]$Parameter1,
        [int]$Parameter2
    )
    
    Write-Output "Test"
}
'@

$fileContent | Out-File -FilePath $tempFile -Encoding utf8

# Tester le validateur
Write-Host "Test du validateur de documentation..." -ForegroundColor Cyan
$results = Test-PowerShellDocumentation -Path $tempFile

# Afficher les résultats
Write-Host "Résultats de la validation :" -ForegroundColor Yellow
$results | Format-Table -Property Rule, Line, Severity, Message -AutoSize

# Générer un rapport HTML
$reportPath = Join-Path -Path $PSScriptRoot -ChildPath "SimpleReport.html"
New-PowerShellDocumentationReport -Results $results -Format HTML -OutputPath $reportPath

if (Test-Path -Path $reportPath) {
    Write-Host "Rapport HTML généré avec succès : $reportPath" -ForegroundColor Green
}
else {
    Write-Host "Échec de la génération du rapport HTML" -ForegroundColor Red
}

# Nettoyer les fichiers temporaires
if (Test-Path -Path $tempFile) {
    Remove-Item -Path $tempFile -Force
    Write-Verbose "Fichier temporaire supprimé : $tempFile"
}

Write-Host "Test terminé." -ForegroundColor Yellow
