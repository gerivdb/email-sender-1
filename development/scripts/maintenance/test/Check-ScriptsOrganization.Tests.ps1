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
    Date de crÃ©ation: 2023-06-10
#>

# Importer Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Chemin du script Ã  tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\monitoring\Check-ScriptsOrganization.ps1"

# VÃ©rifier si le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script Check-ScriptsOrganization.ps1 n'existe pas: $scriptPath"
}

# Tests Pester
Describe "Tests du script Check-ScriptsOrganization.ps1" {
    BeforeAll {
        # CrÃ©er un dossier temporaire pour les tests
        $testDir = Join-Path -Path $env:TEMP -ChildPath "CheckScriptsOrganizationTests"
        if (Test-Path -Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force
        }
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null

        # CrÃ©er une structure de dossiers pour les tests
        $maintenanceDir = Join-Path -Path $testDir -ChildPath "maintenance"
        New-Item -Path $maintenanceDir -ItemType Directory -Force | Out-Null

        # CrÃ©er quelques sous-dossiers
        $categories = @('api', 'cleanup', 'paths', 'test', 'utils', 'monitoring')
        foreach ($category in $categories) {
            New-Item -Path (Join-Path -Path $maintenanceDir -ChildPath $category) -ItemType Directory -Force | Out-Null
        }

        # CrÃ©er un dossier pour les rapports
        $reportsDir = Join-Path -Path $testDir -ChildPath "reports"
        New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null

        # CrÃ©er quelques fichiers de test dans les sous-dossiers
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
        # Nettoyer aprÃ¨s les tests
        if (Test-Path -Path $script:testDir) {
            Remove-Item -Path $script:testDir -Recurse -Force
        }
    }

    Context "Tests de fonctionnalitÃ©" {
        It "Le script devrait exister" {
            Test-Path -Path $scriptPath | Should -Be $true
        }

        It "Le script devrait Ãªtre un fichier PowerShell valide" {
            { . $scriptPath } | Should -Not -Throw
        }

        It "Le script devrait contenir la fonction Write-Log" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "function Write-Log"
        }
    }

    Context "Tests d'intÃ©gration - Organisation correcte" {
        It "Devrait gÃ©nÃ©rer un rapport d'organisation" {
            # ExÃ©cuter le script avec les paramÃ¨tres de test
            & $scriptPath -OutputPath $script:reportsDir

            # VÃ©rifier qu'un rapport a Ã©tÃ© gÃ©nÃ©rÃ©
            $reportFiles = Get-ChildItem -Path $script:reportsDir -Filter "organization_report_*.json"
            $reportFiles.Count | Should -BeGreaterThan 0
        }

        It "Le rapport devrait indiquer que l'organisation est correcte" {
            # RÃ©cupÃ©rer le dernier rapport gÃ©nÃ©rÃ©
            $reportFile = Get-ChildItem -Path $script:reportsDir -Filter "organization_report_*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            $report = Get-Content -Path $reportFile.FullName -Raw | ConvertFrom-Json

            # VÃ©rifier que le rapport indique que l'organisation est correcte
            $report.OrganizationStatus | Should -Be "OK"
            $report.RootFilesCount | Should -Be 0
            $report.SubDirsCount | Should -BeGreaterThan 0
            $report.SubDirFilesCount | Should -BeGreaterThan 0
        }
    }

    Context "Tests d'intÃ©gration - Organisation incorrecte" {
        BeforeEach {
            # CrÃ©er quelques fichiers de test Ã  la racine
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
            # Supprimer les fichiers de test Ã  la racine
            Get-ChildItem -Path $script:maintenanceDir -File | Remove-Item -Force
        }

        It "Devrait dÃ©tecter les fichiers Ã  la racine" {
            # ExÃ©cuter le script avec les paramÃ¨tres de test
            & $scriptPath -OutputPath $script:reportsDir

            # RÃ©cupÃ©rer le dernier rapport gÃ©nÃ©rÃ©
            $reportFile = Get-ChildItem -Path $script:reportsDir -Filter "organization_report_*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            $report = Get-Content -Path $reportFile.FullName -Raw | ConvertFrom-Json

            # VÃ©rifier que le rapport indique que l'organisation est incorrecte
            $report.OrganizationStatus | Should -Be "PROBLÃˆME"
            $report.RootFilesCount | Should -Be 2
            $report.RootFiles.Count | Should -Be 2
        }
    }
}
