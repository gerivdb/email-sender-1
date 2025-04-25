#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le système d'inventaire et de classification des scripts
.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier le bon fonctionnement
    du système d'inventaire et de classification des scripts.
.EXAMPLE
    .\Test-ScriptInventorySystem.ps1
.NOTES
    Auteur: Augment Agent
    Version: 1.0
#>
[CmdletBinding()]
param()

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Installation du module Pester..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Utiliser une version spécifique de Pester pour éviter les problèmes de récursion
$pesterModule = Get-Module -Name Pester -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
Import-Module $pesterModule -Force

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\ScriptInventoryManager.psm1"
Import-Module $modulePath -Force

# Créer un répertoire de test temporaire
$testDir = Join-Path -Path $env:TEMP -ChildPath "ScriptInventoryTest_$(Get-Random)"
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

# Créer des fichiers de test
$testFiles = @{
    "Test-Core.ps1"       = @"
<#
.SYNOPSIS
    Script de test pour la catégorie Core
.DESCRIPTION
    Ce script est utilisé pour tester la classification des scripts
.AUTHOR
    Test Author
.VERSION
    1.0
.TAGS
    Test, Core, Initialisation
#>

function Initialize-TestEnvironment {
    # Fonction de test
}
"@
    "Test-Gestion.ps1"    = @"
<#
.SYNOPSIS
    Script de test pour la catégorie Gestion
.DESCRIPTION
    Ce script est utilisé pour tester la classification des scripts
.AUTHOR
    Test Author
.VERSION
    1.0
.TAGS
    Test, Gestion, Admin
#>

function Manage-TestProject {
    # Fonction de test
}
"@
    "Test-Duplicate1.ps1" = @"
# Script dupliqué pour les tests
function Test-Duplicate {
    Write-Host "Test de duplication"
}
"@
    "Test-Duplicate2.ps1" = @"
# Script dupliqué pour les tests
function Test-Duplicate {
    Write-Host "Test de duplication"
}
"@
    "Test-Similar1.ps1"   = @"
# Script similaire pour les tests
function Test-Similar {
    Write-Host "Test de similarité version 1"
}
"@
    "Test-Similar2.ps1"   = @"
# Script similaire pour les tests
function Test-Similar {
    Write-Host "Test de similarité version 2"
}
"@
}

# Créer les fichiers de test
foreach ($file in $testFiles.Keys) {
    $filePath = Join-Path -Path $testDir -ChildPath $file
    Set-Content -Path $filePath -Value $testFiles[$file]
}

# Définir la taxonomie et les règles de classification pour les tests
$taxonomy = @{
    "Core"    = @{
        Description   = "Scripts fondamentaux du projet"
        SubCategories = @{
            "Initialisation" = "Scripts de démarrage et configuration"
        }
    }
    "Gestion" = @{
        Description   = "Scripts de gestion et administration"
        SubCategories = @{
            "Admin" = "Administration"
        }
    }
}

$classificationRules = @{
    "Core"    = @{
        Patterns = @("Core")
        Keywords = @("Initialize")
    }
    "Gestion" = @{
        Patterns = @("Gestion")
        Keywords = @("Manage")
    }
}

# Exécuter les tests
Describe "Tests du système d'inventaire et de classification des scripts" {
    Context "Test de l'inventaire des scripts" {
        It "Doit scanner correctement le répertoire de test" {
            $scripts = Get-ScriptInventory -Path $testDir -ForceRescan
            $scripts.Count | Should -Be 6
        }

        It "Doit extraire correctement les métadonnées" {
            $scripts = Get-ScriptInventory -Path $testDir
            $coreScript = $scripts | Where-Object { $_.FileName -eq "Test-Core.ps1" }
            $coreScript.Author | Should -Be "Test Author"
            $coreScript.Version | Should -Be "1.0"
        }
    }

    Context "Test de détection des scripts dupliqués" {
        It "Doit détecter les scripts dupliqués" {
            $duplicates = Get-ScriptDuplicates -SimilarityThreshold 100
            ($duplicates | Where-Object { $_.Type -eq "Duplicate" }).Count | Should -BeGreaterOrEqual 1
        }

        It "Doit détecter les scripts similaires" {
            $similar = Get-ScriptDuplicates -SimilarityThreshold 80
            ($similar | Where-Object { $_.Type -eq "Similar" }).Count | Should -BeGreaterOrEqual 1
        }
    }

    Context "Test de classification des scripts" {
        It "Doit classifier correctement les scripts" {
            $classified = Invoke-ScriptClassification -Taxonomy $taxonomy -ClassificationRules $classificationRules
            ($classified | Where-Object { $_.FileName -eq "Test-Core.ps1" }).Category | Should -Be "Core"
            ($classified | Where-Object { $_.FileName -eq "Test-Gestion.ps1" }).Category | Should -Be "Gestion"
        }
    }

    Context "Test d'export de l'inventaire" {
        It "Doit exporter l'inventaire au format CSV" {
            $exportPath = Join-Path -Path $testDir -ChildPath "inventory.csv"
            Export-ScriptInventory -Path $exportPath -Format "CSV"
            Test-Path $exportPath | Should -Be $true
        }

        It "Doit exporter l'inventaire au format HTML" {
            $exportPath = Join-Path -Path $testDir -ChildPath "inventory.html"
            Export-ScriptInventory -Path $exportPath -Format "HTML"
            Test-Path $exportPath | Should -Be $true
        }
    }
}

# Nettoyer les fichiers de test
Remove-Item -Path $testDir -Recurse -Force

# Afficher un résumé
Write-Host "`nTests terminés. Vérifiez les résultats ci-dessus." -ForegroundColor Green
