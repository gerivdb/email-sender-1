#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Check-ScriptsOrganization.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Check-ScriptsOrganization.ps1,
    en utilisant le framework Pester.
.EXAMPLE
    Invoke-Pester -Path ".\Check-ScriptsOrganization.Tests.ps1"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-10
#>

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\monitoring\Check-ScriptsOrganization.ps1"

# Vérifier si le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script Check-ScriptsOrganization.ps1 n'existe pas: $scriptPath"
}

# Tests Pester
Describe "Tests du script Check-ScriptsOrganization.ps1" {
    BeforeAll {
        # Créer un dossier temporaire pour les tests
        $testDir = Join-Path -Path $env:TEMP -ChildPath "CheckScriptsOrganizationTests"
        if (Test-Path -Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force
        }
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null

        # Créer une structure de dossiers pour les tests
        $maintenanceDir = Join-Path -Path $testDir -ChildPath "maintenance"
        New-Item -Path $maintenanceDir -ItemType Directory -Force | Out-Null

        # Créer quelques sous-dossiers
        $categories = @('api', 'cleanup', 'paths', 'test', 'utils', 'monitoring')
        foreach ($category in $categories) {
            New-Item -Path (Join-Path -Path $maintenanceDir -ChildPath $category) -ItemType Directory -Force | Out-Null
        }

        # Créer un dossier pour les rapports
        $reportsDir = Join-Path -Path $testDir -ChildPath "reports"
        New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null

        # Créer quelques fichiers de test dans les sous-dossiers
        $subDirFiles = @(
            @{Path = "api\Analyze-Data.ps1"; Content = "# Analyze data script" },
            @{Path = "cleanup\Fix-Issues.ps1"; Content = "# Fix issues script" },
            @{Path = "paths\Update-Paths.ps1"; Content = "# Update paths script" },
            @{Path = "test\Test-Script.ps1"; Content = "# Test script" },
            @{Path = "utils\Random-Script.ps1"; Content = "# Random script" },
            @{Path = "monitoring\Check-ScriptsOrganization.ps1"; Content = "# Check organization script" }
        )

        foreach ($file in $subDirFiles) {
            $filePath = Join-Path -Path $maintenanceDir -ChildPath $file.Path
            Set-Content -Path $filePath -Value $file.Content -Encoding UTF8
        }

        # Sauvegarder les chemins pour les tests
        $script:testDir = $testDir
        $script:maintenanceDir = $maintenanceDir
        $script:reportsDir = $reportsDir
        $script:subDirFiles = $subDirFiles
    }

    AfterAll {
        # Nettoyer après les tests
        if (Test-Path -Path $script:testDir) {
            Remove-Item -Path $script:testDir -Recurse -Force
        }
    }

    Context "Tests de fonctionnalité" {
        It "Le script devrait exister" {
            Test-Path -Path $scriptPath | Should -Be $true
        }

        It "Le script devrait être un fichier PowerShell valide" {
            { . $scriptPath } | Should -Not -Throw
        }

        It "Le script devrait contenir la fonction Write-Log" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "function Write-Log"
        }
    }

    Context "Tests d'intégration - Organisation correcte" {
        It "Devrait générer un rapport d'organisation" {
            # Exécuter le script avec les paramètres de test
            & $scriptPath -OutputPath $script:reportsDir

            # Vérifier qu'un rapport a été généré
            $reportFiles = Get-ChildItem -Path $script:reportsDir -Filter "organization_report_*.json"
            $reportFiles.Count | Should -BeGreaterThan 0
        }

        It "Le rapport devrait indiquer que l'organisation est correcte" {
            # Récupérer le dernier rapport généré
            $reportFile = Get-ChildItem -Path $script:reportsDir -Filter "organization_report_*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            $report = Get-Content -Path $reportFile.FullName -Raw | ConvertFrom-Json

            # Vérifier que le rapport indique que l'organisation est correcte
            $report.OrganizationStatus | Should -Be "OK"
            $report.RootFilesCount | Should -Be 0
            $report.SubDirsCount | Should -BeGreaterThan 0
            $report.SubDirFilesCount | Should -BeGreaterThan 0
        }
    }

    Context "Tests d'intégration - Organisation incorrecte" {
        BeforeEach {
            # Créer quelques fichiers de test à la racine
            $rootFiles = @(
                @{Name = "test-script-at-root.ps1"; Content = "# Test script at root" },
                @{Name = "update-paths-at-root.ps1"; Content = "# Update paths script at root" }
            )

            foreach ($file in $rootFiles) {
                $filePath = Join-Path -Path $script:maintenanceDir -ChildPath $file.Name
                Set-Content -Path $filePath -Value $file.Content -Encoding UTF8
            }
        }

        AfterEach {
            # Supprimer les fichiers de test à la racine
            Get-ChildItem -Path $script:maintenanceDir -File | Remove-Item -Force
        }

        It "Devrait détecter les fichiers à la racine" {
            # Exécuter le script avec les paramètres de test
            & $scriptPath -OutputPath $script:reportsDir

            # Récupérer le dernier rapport généré
            $reportFile = Get-ChildItem -Path $script:reportsDir -Filter "organization_report_*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            $report = Get-Content -Path $reportFile.FullName -Raw | ConvertFrom-Json

            # Vérifier que le rapport indique que l'organisation est incorrecte
            $report.OrganizationStatus | Should -Be "PROBLÈME"
            $report.RootFilesCount | Should -Be 2
            $report.RootFiles.Count | Should -Be 2
        }
    }
}
