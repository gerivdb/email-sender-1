<#
.SYNOPSIS
    Script pour exécuter les tests de la fonction Inspect-Variable.

.DESCRIPTION
    Ce script exécute les tests de la fonction Inspect-Variable en s'assurant
    que la fonction est correctement importée dans l'environnement de test.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Chemin vers le module
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$moduleFile = Join-Path -Path $modulePath -ChildPath "RoadmapParser.psm1"

# Vérifier si le module existe
if (-not (Test-Path -Path $moduleFile)) {
    throw "Le module RoadmapParser est introuvable à l'emplacement : $moduleFile"
}

# Importer le module
Import-Module -Name $moduleFile -Force
Write-Host "Module RoadmapParser importé depuis : $moduleFile" -ForegroundColor Green

# Vérifier que la fonction est disponible
if (-not (Get-Command -Name Inspect-Variable -ErrorAction SilentlyContinue)) {
    throw "La fonction Inspect-Variable n'est pas disponible après l'importation du module."
}

# Importer Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation..."
    Install-Module -Name Pester -Scope CurrentUser -Force
}

# Importer le module Pester
Import-Module -Name Pester

# Exécuter les tests
Write-Host "Exécution des tests..." -ForegroundColor Cyan
Invoke-Pester -Path (Join-Path -Path $scriptPath -ChildPath "Test-InspectVariable.ps1") -Output Detailed
