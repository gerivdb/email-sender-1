<#
.SYNOPSIS
Teste le système d'inventaire et de classification des scripts

.DESCRIPTION
Ce script vérifie que :
- Le module ScriptInventoryManager fonctionne correctement
- La détection des scripts redondants est efficace
- La classification des scripts est cohérente
#>

# Charger les modules nécessaires
Import-Module $PSScriptRoot/../../modules/ScriptInventoryManager.psm1 -Force
Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

Describe "Tests du système d'inventaire des scripts" {
    BeforeAll {
        # Créer un environnement de test temporaire
        $testDir = "TestDrive:\script_test"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null

        # Créer des scripts de test
        @'
<#
.Author: TestUser
.Version: 1.0
.Description: Script de test core
.Tags: test,core
#>
function Test-Core { Write-Output "Core function" }
'@ | Out-File "$testDir\Test-Core.ps1"

        @'
<#
.Author: TestUser
.Version: 2.0
.Description: Script de test gestion
.Tags: test,gestion
#>
function Test-Gestion { Write-Output "Gestion function" }
'@ | Out-File "$testDir\Test-Gestion.ps1"

        # Copie légèrement modifiée pour tester la détection de similarité
        @'
<#
.Author: TestUser
.Version: 1.1
.Description: Script de test core modifié
.Tags: test,core,modified
#>
function Test-Core { Write-Output "Core function modified" }
'@ | Out-File "$testDir\Test-Core-Modified.ps1"
    }

    Context "Test du module ScriptInventoryManager" {
        It "Doit détecter les 3 scripts de test" {
            $scripts = Get-ScriptInventory -Path $testDir -ForceRescan
            $scripts.Count | Should -Be 3
        }

        It "Doit extraire correctement les métadonnées" {
            $scripts = Get-ScriptInventory -Path $testDir -ForceRescan
            $script = $scripts | Where-Object { $_.FileName -eq "Test-Core.ps1" } | Select-Object -First 1
            $script.Author | Should -BeExactly "TestUser"
            $script.Version | Should -BeExactly "1.0"
            $script.Tags | Should -Contain "test"
            $script.Tags | Should -Contain "core"
        }
    }

    Context "Test de détection des scripts redondants" {
        It "Doit détecter les scripts similaires" {
            $result = & "$PSScriptRoot/../analysis/Find-RedundantScripts.ps1" -Path $testDir -SimilarityThreshold 80
            $result | Should -Not -BeNullOrEmpty
            ($result | Where-Object { $_.Script1 -like "*Test-Core*" -and $_.Script2 -like "*Test-Core*" }).Count | Should -BeGreaterThan 0
        }
    }

    Context "Test de classification des scripts" {
        It "Doit classifier correctement les scripts" {
            $result = & "$PSScriptRoot/../analysis/Classify-Scripts.ps1" -Path $testDir
            ($result | Where-Object { $_.ScriptName -eq "Test-Core.ps1" }).Category | Should -Be "Core"
            ($result | Where-Object { $_.ScriptName -eq "Test-Gestion.ps1" }).Category | Should -Be "Gestion"
        }
    }

    AfterAll {
        # Nettoyage automatique par Pester (TestDrive)
    }
}
