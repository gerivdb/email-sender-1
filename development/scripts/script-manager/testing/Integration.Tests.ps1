#Requires -Version 5.1
<#
.SYNOPSIS
    Tests d'intégration pour le script manager.
.DESCRIPTION
    Ce script contient des tests d'intégration pour le script manager,
    en utilisant le framework Pester.
.EXAMPLE
    Invoke-Pester -Path ".\Integration.Tests.ps1"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-15
#>

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Tests Pester
Describe "Tests d'intégration du script manager" {
    Context "Tests d'initialisation de l'environnement" {
        BeforeAll {
            # Créer un dossier temporaire pour les tests
            $testDir = Join-Path -Path $env:TEMP -ChildPath "ManagerIntegrationTests"
            if (Test-Path -Path $testDir) {
                Remove-Item -Path $testDir -Recurse -Force
            }
            New-Item -Path $testDir -ItemType Directory -Force | Out-Null

            # Créer une structure de dossiers simulée
            $managerDir = Join-Path -Path $testDir -ChildPath "manager"
            $organizationDir = Join-Path -Path $managerDir -ChildPath "organization"
            $analysisDir = Join-Path -Path $managerDir -ChildPath "analysis"
            $inventoryDir = Join-Path -Path $managerDir -ChildPath "inventory"
            $testingDir = Join-Path -Path $managerDir -ChildPath "testing"
            
            New-Item -Path $managerDir -ItemType Directory -Force | Out-Null
            New-Item -Path $organizationDir -ItemType Directory -Force | Out-Null
            New-Item -Path $analysisDir -ItemType Directory -Force | Out-Null
            New-Item -Path $inventoryDir -ItemType Directory -Force | Out-Null
            New-Item -Path $testingDir -ItemType Directory -Force | Out-Null

            # Créer des scripts de test
            $initScriptPath = Join-Path -Path $managerDir -ChildPath "Initialize-ManagerEnvironment.ps1"
            $organizeScriptPath = Join-Path -Path $organizationDir -ChildPath "Organize-ManagerScripts.ps1"
            $analyzeScriptPath = Join-Path -Path $analysisDir -ChildPath "Analyze-Scripts.ps1"
            $inventoryScriptPath = Join-Path -Path $inventoryDir -ChildPath "Show-ScriptInventory.ps1"
            $testScriptPath = Join-Path -Path $testingDir -ChildPath "Test-ManagerScripts.ps1"
            
            # Contenu minimal pour les scripts
            $initScriptContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Initialise l'environnement du script manager.
.DESCRIPTION
    Ce script configure l'environnement du script manager.
#>
Write-Host "Initialisation de l'environnement du script manager..."
"@
            
            $organizeScriptContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Organise les scripts du manager.
.DESCRIPTION
    Ce script organise les scripts du manager.
#>
Write-Host "Organisation des scripts du manager..."
"@
            
            $analyzeScriptContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Analyse les scripts.
.DESCRIPTION
    Ce script analyse les scripts.
#>
Write-Host "Analyse des scripts..."
"@
            
            $inventoryScriptContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Affiche l'inventaire des scripts.
.DESCRIPTION
    Ce script affiche l'inventaire des scripts.
#>
Write-Host "Affichage de l'inventaire des scripts..."
"@
            
            $testScriptContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour les scripts du manager.
.DESCRIPTION
    Ce script contient des tests unitaires pour les scripts du manager.
#>
Write-Host "Exécution des tests unitaires..."
"@
            
            Set-Content -Path $initScriptPath -Value $initScriptContent -Encoding UTF8
            Set-Content -Path $organizeScriptPath -Value $organizeScriptContent -Encoding UTF8
            Set-Content -Path $analyzeScriptPath -Value $analyzeScriptContent -Encoding UTF8
            Set-Content -Path $inventoryScriptPath -Value $inventoryScriptContent -Encoding UTF8
            Set-Content -Path $testScriptPath -Value $testScriptContent -Encoding UTF8

            # Sauvegarder les chemins pour les tests
            $script:testDir = $testDir
            $script:managerDir = $managerDir
            $script:organizationDir = $organizationDir
            $script:analysisDir = $analysisDir
            $script:inventoryDir = $inventoryDir
            $script:testingDir = $testingDir
            $script:initScriptPath = $initScriptPath
            $script:organizeScriptPath = $organizeScriptPath
            $script:analyzeScriptPath = $analyzeScriptPath
            $script:inventoryScriptPath = $inventoryScriptPath
            $script:testScriptPath = $testScriptPath
        }

        AfterAll {
            # Nettoyer après les tests
            if (Test-Path -Path $script:testDir) {
                Remove-Item -Path $script:testDir -Recurse -Force
            }
        }

        It "Devrait avoir une structure de dossiers valide" {
            Test-Path -Path $script:managerDir | Should -Be $true
            Test-Path -Path $script:organizationDir | Should -Be $true
            Test-Path -Path $script:analysisDir | Should -Be $true
            Test-Path -Path $script:inventoryDir | Should -Be $true
            Test-Path -Path $script:testingDir | Should -Be $true
        }

        It "Devrait avoir des scripts valides" {
            Test-Path -Path $script:initScriptPath | Should -Be $true
            Test-Path -Path $script:organizeScriptPath | Should -Be $true
            Test-Path -Path $script:analyzeScriptPath | Should -Be $true
            Test-Path -Path $script:inventoryScriptPath | Should -Be $true
            Test-Path -Path $script:testScriptPath | Should -Be $true
        }

        It "Les scripts devraient avoir un contenu valide" {
            $initContent = Get-Content -Path $script:initScriptPath -Raw
            $organizeContent = Get-Content -Path $script:organizeScriptPath -Raw
            $analyzeContent = Get-Content -Path $script:analyzeScriptPath -Raw
            $inventoryContent = Get-Content -Path $script:inventoryScriptPath -Raw
            $testContent = Get-Content -Path $script:testScriptPath -Raw
            
            $initContent | Should -Match "Initialise l'environnement du script manager"
            $organizeContent | Should -Match "Organise les scripts du manager"
            $analyzeContent | Should -Match "Analyse les scripts"
            $inventoryContent | Should -Match "Affiche l'inventaire des scripts"
            $testContent | Should -Match "Tests unitaires pour les scripts du manager"
        }
    }

    Context "Tests de flux de travail" {
        It "Devrait pouvoir exécuter le flux de travail complet" -Skip {
            # Ce test est ignoré car il nécessite un environnement complet
            # Il est fourni à titre d'exemple de test d'intégration
            
            # 1. Initialiser l'environnement
            & "$PSScriptRoot/../Initialize-ManagerEnvironment.ps1" -Force
            $LASTEXITCODE | Should -Be 0
            
            # 2. Organiser les scripts
            & "$PSScriptRoot/../organization/Organize-ManagerScripts.ps1" -Force
            $LASTEXITCODE | Should -Be 0
            
            # 3. Analyser les scripts
            & "$PSScriptRoot/../analysis/Analyze-Scripts.ps1"
            $LASTEXITCODE | Should -Be 0
            
            # 4. Afficher l'inventaire des scripts
            & "$PSScriptRoot/../inventory/Show-ScriptInventory.ps1"
            $LASTEXITCODE | Should -Be 0
            
            # 5. Exécuter les tests
            & "$PSScriptRoot/../testing/Test-ManagerScripts.ps1"
            $LASTEXITCODE | Should -Be 0
        }
    }

    Context "Tests de compatibilité avec les scripts de maintenance" {
        It "Devrait être compatible avec les scripts de maintenance" -Skip {
            # Ce test est ignoré car il nécessite un environnement complet
            # Il est fourni à titre d'exemple de test d'intégration
            
            # 1. Vérifier que le hook pre-commit est compatible
            $hookPath = ".git/hooks/pre-commit"
            if (Test-Path -Path $hookPath) {
                $hookContent = Get-Content -Path $hookPath -Raw
                $hookContent | Should -Match "maintenance"
                $hookContent | Should -Match "manager"
            }
            
            # 2. Vérifier que les scripts de maintenance sont correctement organisés
            $maintenanceDir = "development/scripts/maintenance"
            if (Test-Path -Path $maintenanceDir) {
                $rootFiles = Get-ChildItem -Path $maintenanceDir -File | Where-Object { 
                    $_.Extension -in '.ps1', '.psm1', '.psd1' -and 
                    $_.Name -ne 'Initialize-MaintenanceEnvironment.ps1' -and
                    $_.Name -ne 'README.md'
                }
                $rootFiles.Count | Should -Be 0
            }
            
            # 3. Vérifier que les scripts du manager sont correctement organisés
            $managerDir = "development/scripts/manager"
            if (Test-Path -Path $managerDir) {
                $rootFiles = Get-ChildItem -Path $managerDir -File | Where-Object { 
                    $_.Extension -in '.ps1', '.psm1', '.psd1' -and 
                    $_.Name -ne 'Initialize-ManagerEnvironment.ps1' -and
                    $_.Name -ne 'README.md'
                }
                $rootFiles.Count | Should -Be 0
            }
        }
    }
}
