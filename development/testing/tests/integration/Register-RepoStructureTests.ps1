#Requires -Version 5.1
<#
.SYNOPSIS
    Enregistre les tests de rÃ©organisation et standardisation du dÃ©pÃ´t dans TestOmnibus
.DESCRIPTION
    Ce script enregistre les tests unitaires et d'intÃ©gration pour les scripts
    de rÃ©organisation et standardisation du dÃ©pÃ´t dans le systÃ¨me TestOmnibus.
.PARAMETER TestOmnibusPath
    Chemin du module TestOmnibus
.EXAMPLE
    .\Register-RepoStructureTests.ps1 -TestOmnibusPath "D:\Repos\EMAIL_SENDER_1\modules\TestOmnibus"
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Date: 2025-04-26
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$TestOmnibusPath = (Join-Path -Path (Get-Location).Path -ChildPath "modules\TestOmnibus")
)

# VÃ©rifier que le module TestOmnibus existe
if (-not (Test-Path -Path $TestOmnibusPath -PathType Container)) {
    Write-Error "Le module TestOmnibus n'existe pas Ã  l'emplacement spÃ©cifiÃ©: $TestOmnibusPath"
    exit 1
}

# Importer le module TestOmnibus
$modulePath = Join-Path -Path $TestOmnibusPath -ChildPath "TestOmnibus.psm1"
if (Test-Path -Path $modulePath -PathType Leaf) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Le fichier TestOmnibus.psm1 n'existe pas Ã  l'emplacement spÃ©cifiÃ©: $modulePath"
    exit 1
}

# DÃ©finir les informations des tests
$testSuite = @{
    Name = "RepoStructure"
    Description = "Tests pour la rÃ©organisation et standardisation du dÃ©pÃ´t"
    Category = "Infrastructure"
    Tags = @("RepoStructure", "Standardization", "Maintenance")
    Priority = "High"
    TestFiles = @(
        @{
            Path = "tests\unit\Test-RepoStructureUnit.ps1"
            Type = "Unit"
            Description = "Tests unitaires pour la validation de structure du dÃ©pÃ´t"
        },
        @{
            Path = "tests\unit\Test-RepositoryMigration.ps1"
            Type = "Unit"
            Description = "Tests unitaires pour la migration du dÃ©pÃ´t"
        },
        @{
            Path = "tests\unit\Test-RepositoryCleaning.ps1"
            Type = "Unit"
            Description = "Tests unitaires pour le nettoyage du dÃ©pÃ´t"
        },
        @{
            Path = "tests\Test-RepoStructureIntegration.ps1"
            Type = "Integration"
            Description = "Tests d'intÃ©gration pour la rÃ©organisation et standardisation du dÃ©pÃ´t"
            Parameters = @{
                OutputFormat = "HTML"
                CoverageReport = $true
            }
        }
    )
    DependsOn = @()
    SetupScript = $null
    TeardownScript = $null
}

# Enregistrer la suite de tests dans TestOmnibus
if (Get-Command -Name Register-TestSuite -ErrorAction SilentlyContinue) {
    Register-TestSuite -TestSuite $testSuite
    Write-Host "Suite de tests 'RepoStructure' enregistrÃ©e avec succÃ¨s dans TestOmnibus." -ForegroundColor Green
} else {
    Write-Error "La commande Register-TestSuite n'est pas disponible. VÃ©rifiez que le module TestOmnibus est correctement importÃ©."
    exit 1
}

# CrÃ©er un script de raccourci pour exÃ©cuter les tests
$shortcutScript = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute les tests de rÃ©organisation et standardisation du dÃ©pÃ´t
.DESCRIPTION
    Ce script exÃ©cute tous les tests unitaires et d'intÃ©gration pour les scripts
    de rÃ©organisation et standardisation du dÃ©pÃ´t.
.PARAMETER OutputFormat
    Format de sortie du rapport (NUnitXml, JUnitXml, HTML)
.PARAMETER CoverageReport
    Indique s'il faut gÃ©nÃ©rer un rapport de couverture
.EXAMPLE
    .\Run-RepoStructureTests.ps1 -OutputFormat HTML -CoverageReport
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = \$false)]
    [ValidateSet("NUnitXml", "JUnitXml", "HTML")]
    [string]\$OutputFormat = "HTML",
    
    [Parameter(Mandatory = \$false)]
    [switch]\$CoverageReport
)

# Importer le module TestOmnibus
Import-Module "$PSScriptRoot\..\..\modules\TestOmnibus\TestOmnibus.psm1" -Force

# ExÃ©cuter la suite de tests
Invoke-TestSuite -Name "RepoStructure" -Parameters @{
    OutputFormat = \$OutputFormat
    CoverageReport = \$CoverageReport
}
"@

$shortcutPath = "tests\Run-RepoStructureTests.ps1"
Set-Content -Path $shortcutPath -Value $shortcutScript -Encoding UTF8

Write-Host "Script de raccourci crÃ©Ã©: $shortcutPath" -ForegroundColor Green

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© de l'enregistrement:" -ForegroundColor Cyan
Write-Host "- Suite de tests: RepoStructure" -ForegroundColor White
Write-Host "- CatÃ©gorie: Infrastructure" -ForegroundColor White
Write-Host "- PrioritÃ©: High" -ForegroundColor White
Write-Host "- Nombre de tests: $($testSuite.TestFiles.Count)" -ForegroundColor White
Write-Host "- Script de raccourci: $shortcutPath" -ForegroundColor White

# Afficher les instructions d'exÃ©cution
Write-Host "`nPour exÃ©cuter les tests, utilisez l'une des commandes suivantes:" -ForegroundColor Yellow
Write-Host "- Invoke-TestSuite -Name 'RepoStructure'" -ForegroundColor White
Write-Host "- .\development\testing\tests\Run-RepoStructureTests.ps1" -ForegroundColor White
