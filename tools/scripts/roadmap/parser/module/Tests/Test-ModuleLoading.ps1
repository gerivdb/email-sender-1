<#
.SYNOPSIS
    Test le chargement du module RoadmapParserCore.

.DESCRIPTION
    Ce script teste le chargement du module RoadmapParserCore et vérifie que les fonctions sont correctement exportées.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester

# Définir le chemin du module
$modulePath = Split-Path -Parent $PSScriptRoot
$moduleName = "RoadmapParserCore"
$moduleManifestPath = Join-Path -Path $modulePath -ChildPath "$moduleName.psd1"

Describe "Test de chargement du module $moduleName" {
    Context "Vérification du manifeste du module" {
        It "Le fichier manifeste du module existe" {
            Test-Path -Path $moduleManifestPath | Should -Be $true
        }

        It "Le manifeste du module est valide" {
            $manifest = Test-ModuleManifest -Path $moduleManifestPath -ErrorAction SilentlyContinue
            $manifest | Should -Not -BeNullOrEmpty
        }

        It "Le manifeste contient le bon nom de module" {
            $manifest = Test-ModuleManifest -Path $moduleManifestPath -ErrorAction SilentlyContinue
            $manifest.Name | Should -Be $moduleName
        }
    }

    Context "Chargement du module" {
        It "Le module peut être importé sans erreur" {
            { Import-Module -Name $moduleManifestPath -Force -ErrorAction Stop } | Should -Not -Throw
        }

        It "Le module est chargé" {
            Get-Module -Name $moduleName | Should -Not -BeNullOrEmpty
        }
    }

    Context "Vérification des fonctions exportées" {
        BeforeAll {
            Import-Module -Name $moduleManifestPath -Force -ErrorAction Stop
            $exportedFunctions = Get-Command -Module $moduleName
        }

        It "Le module exporte des fonctions" {
            $exportedFunctions.Count | Should -BeGreaterThan 0
        }

        $expectedFunctions = @(
            # Fonctions de parsing du markdown
            'ConvertFrom-MarkdownToRoadmap',

            # Fonctions de manipulation de l'arbre
            'New-RoadmapTree',
            'New-RoadmapTask',

            # Fonctions d'export et de génération
            'Export-RoadmapToJson',
            'Import-RoadmapFromJson',

            # Fonctions utilitaires et helpers
            'Write-RoadmapLog',

            # Fonctions des modes opérationnels
            'Invoke-RoadmapArchitecture',
            'Invoke-RoadmapDebug',
            'Invoke-RoadmapTest'
        )

        It "Le module exporte les fonctions essentielles" {
            foreach ($function in $expectedFunctions) {
                $exportedFunctions.Name -contains $function | Should -Be $true -Because "La fonction $function devrait être exportée"
            }
        }
    }

    Context "Vérification de la structure des répertoires" {
        $expectedDirectories = @(
            (Join-Path -Path $modulePath -ChildPath "Functions"),
            (Join-Path -Path $modulePath -ChildPath "Functions\Common"),
            (Join-Path -Path $modulePath -ChildPath "Functions\Private"),
            (Join-Path -Path $modulePath -ChildPath "Functions\Public"),
            (Join-Path -Path $modulePath -ChildPath "Exceptions"),
            (Join-Path -Path $modulePath -ChildPath "Config"),
            (Join-Path -Path $modulePath -ChildPath "Resources"),
            (Join-Path -Path $modulePath -ChildPath "docs")
        )

        It "Les répertoires requis existent" {
            foreach ($directory in $expectedDirectories) {
                Test-Path -Path $directory -PathType Container | Should -Be $true -Because "Le répertoire $directory devrait exister"
            }
        }
    }
}

# Exécuter les tests
# Invoke-Pester -Script $PSCommandPath -Output Detailed
# Commenté pour éviter la récursion infinie
