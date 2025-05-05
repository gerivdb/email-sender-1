<#
.SYNOPSIS
    Tests d'intÃ©gration pour le script mode-manager.ps1.

.DESCRIPTION
    Ce script contient des tests d'intÃ©gration pour vÃ©rifier que le mode MANAGER fonctionne correctement avec les autres modes.
    Il utilise le framework Pester pour exÃ©cuter les tests.

.NOTES
    Auteur: Mode Manager Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Importer le module Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# DÃ©finir le chemin du script Ã  tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\mode-manager.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script mode-manager.ps1 est introuvable Ã  l'emplacement : $scriptPath"
}

# DÃ©finir le chemin du projet
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
if (-not (Test-Path -Path $projectRoot)) {
    $projectRoot = $PSScriptRoot
    while ((Split-Path -Path $projectRoot -Leaf) -ne "EMAIL_SENDER_1" -and (Split-Path -Path $projectRoot) -ne "") {
        $projectRoot = Split-Path -Path $projectRoot
    }
}

# DÃ©finir le chemin de configuration pour les tests
$testConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "test-config.json"

# CrÃ©er un fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $PSScriptRoot -ChildPath "test-roadmap.md"
if (-not (Test-Path -Path $testRoadmapPath)) {
    @"
# Roadmap de test

## TÃ¢ches

- [ ] **1** TÃ¢che 1
  - [ ] **1.1** Sous-tÃ¢che 1.1
  - [ ] **1.2** Sous-tÃ¢che 1.2
    - [ ] **1.2.1** Sous-tÃ¢che 1.2.1
    - [ ] **1.2.2** Sous-tÃ¢che 1.2.2
    - [ ] **1.2.3** Sous-tÃ¢che 1.2.3
  - [ ] **1.3** Sous-tÃ¢che 1.3
- [ ] **2** TÃ¢che 2
  - [ ] **2.1** Sous-tÃ¢che 2.1
  - [ ] **2.2** Sous-tÃ¢che 2.2
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8
}

# DÃ©finir les tests
Describe "Mode Manager Integration Tests" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
        if (-not (Test-Path -Path $testDir)) {
            New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        }

        # CrÃ©er un fichier de configuration temporaire
        $tempConfigPath = Join-Path -Path $testDir -ChildPath "config.json"
        @{
            General = @{
                RoadmapPath = $testRoadmapPath
                ActiveDocumentPath = $testRoadmapPath
                ReportPath = Join-Path -Path $testDir -ChildPath "reports"
                LogPath = Join-Path -Path $testDir -ChildPath "logs"
                DefaultEncoding = "UTF8-BOM"
                ProjectRoot = $projectRoot
            }
            Modes = @{
                Check = @{
                    Enabled = $true
                    ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "mock-check-mode.ps1"
                }
                Gran = @{
                    Enabled = $true
                    ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "mock-gran-mode.ps1"
                }
            }
        } | ConvertTo-Json -Depth 5 | Set-Content -Path $tempConfigPath -Encoding UTF8

        # CrÃ©er des scripts de mode simulÃ©s
        $mockCheckModePath = Join-Path -Path $PSScriptRoot -ChildPath "mock-check-mode.ps1"
        @"
param (
    [Parameter(Mandatory = `$false)]
    [string]`$FilePath,

    [Parameter(Mandatory = `$false)]
    [string]`$TaskIdentifier,

    [Parameter(Mandatory = `$false)]
    [switch]`$Force
)

Write-Host "Mode CHECK exÃ©cutÃ© avec les paramÃ¨tres suivants :"
Write-Host "FilePath : `$FilePath"
Write-Host "TaskIdentifier : `$TaskIdentifier"
Write-Host "Force : `$Force"

# CrÃ©er un fichier de sortie pour vÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ©
`$outputPath = Join-Path -Path "`$PSScriptRoot\temp" -ChildPath "check-mode-output.txt"
@"
FilePath : `$FilePath
TaskIdentifier : `$TaskIdentifier
Force : `$Force
"@ | Set-Content -Path `$outputPath -Encoding UTF8

exit 0
"@ | Set-Content -Path $mockCheckModePath -Encoding UTF8

        $mockGranModePath = Join-Path -Path $PSScriptRoot -ChildPath "mock-gran-mode.ps1"
        @"
param (
    [Parameter(Mandatory = `$false)]
    [string]`$FilePath,

    [Parameter(Mandatory = `$false)]
    [string]`$TaskIdentifier,

    [Parameter(Mandatory = `$false)]
    [switch]`$Force
)

Write-Host "Mode GRAN exÃ©cutÃ© avec les paramÃ¨tres suivants :"
Write-Host "FilePath : `$FilePath"
Write-Host "TaskIdentifier : `$TaskIdentifier"
Write-Host "Force : `$Force"

# CrÃ©er un fichier de sortie pour vÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ©
`$outputPath = Join-Path -Path "`$PSScriptRoot\temp" -ChildPath "gran-mode-output.txt"
@"
FilePath : `$FilePath
TaskIdentifier : `$TaskIdentifier
Force : `$Force
"@ | Set-Content -Path `$outputPath -Encoding UTF8

exit 0
"@ | Set-Content -Path $mockGranModePath -Encoding UTF8
    }

    AfterAll {
        # Supprimer les fichiers temporaires
        $testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
        if (Test-Path -Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force
        }

        # Supprimer les scripts de mode simulÃ©s
        $mockCheckModePath = Join-Path -Path $PSScriptRoot -ChildPath "mock-check-mode.ps1"
        if (Test-Path -Path $mockCheckModePath) {
            Remove-Item -Path $mockCheckModePath -Force
        }

        $mockGranModePath = Join-Path -Path $PSScriptRoot -ChildPath "mock-gran-mode.ps1"
        if (Test-Path -Path $mockGranModePath) {
            Remove-Item -Path $mockGranModePath -Force
        }
    }

    Context "ExÃ©cution des modes via le mode MANAGER" {
        BeforeEach {
            # Supprimer les fichiers de sortie des tests prÃ©cÃ©dents
            $checkOutputPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\check-mode-output.txt"
            if (Test-Path -Path $checkOutputPath) {
                Remove-Item -Path $checkOutputPath -Force
            }

            $granOutputPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\gran-mode-output.txt"
            if (Test-Path -Path $granOutputPath) {
                Remove-Item -Path $granOutputPath -Force
            }
        }

        It "Devrait exÃ©cuter le mode CHECK via le mode MANAGER" {
            # ExÃ©cuter le mode CHECK via le mode MANAGER
            $tempConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\config.json"
            & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath

            # VÃ©rifier que le fichier de sortie du mode CHECK a Ã©tÃ© crÃ©Ã©
            $checkOutputPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\check-mode-output.txt"
            Test-Path -Path $checkOutputPath | Should -Be $true

            # VÃ©rifier le contenu du fichier de sortie
            $checkOutput = Get-Content -Path $checkOutputPath -Raw
            $checkOutput | Should -Match "FilePath : $([regex]::Escape($testRoadmapPath))"
            $checkOutput | Should -Match "TaskIdentifier : 1.2.3"
        }

        It "Devrait exÃ©cuter le mode GRAN via le mode MANAGER" {
            # ExÃ©cuter le mode GRAN via le mode MANAGER
            $tempConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\config.json"
            & $scriptPath -Mode "GRAN" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath

            # VÃ©rifier que le fichier de sortie du mode GRAN a Ã©tÃ© crÃ©Ã©
            $granOutputPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\gran-mode-output.txt"
            Test-Path -Path $granOutputPath | Should -Be $true

            # VÃ©rifier le contenu du fichier de sortie
            $granOutput = Get-Content -Path $granOutputPath -Raw
            $granOutput | Should -Match "FilePath : $([regex]::Escape($testRoadmapPath))"
            $granOutput | Should -Match "TaskIdentifier : 1.2.3"
        }

        It "Devrait exÃ©cuter une chaÃ®ne de modes via le mode MANAGER" {
            # ExÃ©cuter une chaÃ®ne de modes via le mode MANAGER
            $tempConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\config.json"
            & $scriptPath -Chain "GRAN,CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath

            # VÃ©rifier que les fichiers de sortie des deux modes ont Ã©tÃ© crÃ©Ã©s
            $granOutputPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\gran-mode-output.txt"
            Test-Path -Path $granOutputPath | Should -Be $true

            $checkOutputPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\check-mode-output.txt"
            Test-Path -Path $checkOutputPath | Should -Be $true

            # VÃ©rifier le contenu des fichiers de sortie
            $granOutput = Get-Content -Path $granOutputPath -Raw
            $granOutput | Should -Match "FilePath : $([regex]::Escape($testRoadmapPath))"
            $granOutput | Should -Match "TaskIdentifier : 1.2.3"

            $checkOutput = Get-Content -Path $checkOutputPath -Raw
            $checkOutput | Should -Match "FilePath : $([regex]::Escape($testRoadmapPath))"
            $checkOutput | Should -Match "TaskIdentifier : 1.2.3"
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Path $PSScriptRoot
