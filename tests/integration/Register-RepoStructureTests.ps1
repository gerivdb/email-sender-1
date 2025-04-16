#Requires -Version 5.1
<#
.SYNOPSIS
    Enregistre les tests de réorganisation et standardisation du dépôt dans TestOmnibus
.DESCRIPTION
    Ce script enregistre les tests unitaires et d'intégration pour les scripts
    de réorganisation et standardisation du dépôt dans le système TestOmnibus.
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

# Vérifier que le module TestOmnibus existe
if (-not (Test-Path -Path $TestOmnibusPath -PathType Container)) {
    Write-Error "Le module TestOmnibus n'existe pas à l'emplacement spécifié: $TestOmnibusPath"
    exit 1
}

# Importer le module TestOmnibus
$modulePath = Join-Path -Path $TestOmnibusPath -ChildPath "TestOmnibus.psm1"
if (Test-Path -Path $modulePath -PathType Leaf) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Le fichier TestOmnibus.psm1 n'existe pas à l'emplacement spécifié: $modulePath"
    exit 1
}

# Définir les informations des tests
$testSuite = @{
    Name = "RepoStructure"
    Description = "Tests pour la réorganisation et standardisation du dépôt"
    Category = "Infrastructure"
    Tags = @("RepoStructure", "Standardization", "Maintenance")
    Priority = "High"
    TestFiles = @(
        @{
            Path = "tests\unit\Test-RepoStructureUnit.ps1"
            Type = "Unit"
            Description = "Tests unitaires pour la validation de structure du dépôt"
        },
        @{
            Path = "tests\unit\Test-RepositoryMigration.ps1"
            Type = "Unit"
            Description = "Tests unitaires pour la migration du dépôt"
        },
        @{
            Path = "tests\unit\Test-RepositoryCleaning.ps1"
            Type = "Unit"
            Description = "Tests unitaires pour le nettoyage du dépôt"
        },
        @{
            Path = "tests\Test-RepoStructureIntegration.ps1"
            Type = "Integration"
            Description = "Tests d'intégration pour la réorganisation et standardisation du dépôt"
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
    Write-Host "Suite de tests 'RepoStructure' enregistrée avec succès dans TestOmnibus." -ForegroundColor Green
} else {
    Write-Error "La commande Register-TestSuite n'est pas disponible. Vérifiez que le module TestOmnibus est correctement importé."
    exit 1
}

# Créer un script de raccourci pour exécuter les tests
$shortcutScript = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute les tests de réorganisation et standardisation du dépôt
.DESCRIPTION
    Ce script exécute tous les tests unitaires et d'intégration pour les scripts
    de réorganisation et standardisation du dépôt.
.PARAMETER OutputFormat
    Format de sortie du rapport (NUnitXml, JUnitXml, HTML)
.PARAMETER CoverageReport
    Indique s'il faut générer un rapport de couverture
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

# Exécuter la suite de tests
Invoke-TestSuite -Name "RepoStructure" -Parameters @{
    OutputFormat = \$OutputFormat
    CoverageReport = \$CoverageReport
}
"@

$shortcutPath = "tests\Run-RepoStructureTests.ps1"
Set-Content -Path $shortcutPath -Value $shortcutScript -Encoding UTF8

Write-Host "Script de raccourci créé: $shortcutPath" -ForegroundColor Green

# Afficher un résumé
Write-Host "`nRésumé de l'enregistrement:" -ForegroundColor Cyan
Write-Host "- Suite de tests: RepoStructure" -ForegroundColor White
Write-Host "- Catégorie: Infrastructure" -ForegroundColor White
Write-Host "- Priorité: High" -ForegroundColor White
Write-Host "- Nombre de tests: $($testSuite.TestFiles.Count)" -ForegroundColor White
Write-Host "- Script de raccourci: $shortcutPath" -ForegroundColor White

# Afficher les instructions d'exécution
Write-Host "`nPour exécuter les tests, utilisez l'une des commandes suivantes:" -ForegroundColor Yellow
Write-Host "- Invoke-TestSuite -Name 'RepoStructure'" -ForegroundColor White
Write-Host "- .\tests\Run-RepoStructureTests.ps1" -ForegroundColor White
