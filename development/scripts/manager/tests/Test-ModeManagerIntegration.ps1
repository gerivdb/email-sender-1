<#
.SYNOPSIS
    Tests d'intégration pour le script mode-manager.ps1.

.DESCRIPTION
    Ce script contient des tests d'intégration pour vérifier que le mode MANAGER fonctionne correctement avec les autres modes.
    Il utilise le framework Pester pour exécuter les tests.

.NOTES
    Auteur: Mode Manager Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Importer le module Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Définir le chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\mode-manager.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script mode-manager.ps1 est introuvable à l'emplacement : $scriptPath"
}

# Définir le chemin du projet
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
if (-not (Test-Path -Path $projectRoot)) {
    $projectRoot = $PSScriptRoot
    while ((Split-Path -Path $projectRoot -Leaf) -ne "EMAIL_SENDER_1" -and (Split-Path -Path $projectRoot) -ne "") {
        $projectRoot = Split-Path -Path $projectRoot
    }
}

# Définir le chemin de configuration pour les tests
$testConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "test-config.json"

# Créer un fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $PSScriptRoot -ChildPath "test-roadmap.md"
if (-not (Test-Path -Path $testRoadmapPath)) {
    @"
# Roadmap de test

## Tâches

- [ ] **1** Tâche 1
  - [ ] **1.1** Sous-tâche 1.1
  - [ ] **1.2** Sous-tâche 1.2
    - [ ] **1.2.1** Sous-tâche 1.2.1
    - [ ] **1.2.2** Sous-tâche 1.2.2
    - [ ] **1.2.3** Sous-tâche 1.2.3
  - [ ] **1.3** Sous-tâche 1.3
- [ ] **2** Tâche 2
  - [ ] **2.1** Sous-tâche 2.1
  - [ ] **2.2** Sous-tâche 2.2
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8
}

# Définir les tests
Describe "Mode Manager Integration Tests" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
        if (-not (Test-Path -Path $testDir)) {
            New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        }

        # Créer un fichier de configuration temporaire
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

        # Créer des scripts de mode simulés
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

Write-Host "Mode CHECK exécuté avec les paramètres suivants :"
Write-Host "FilePath : `$FilePath"
Write-Host "TaskIdentifier : `$TaskIdentifier"
Write-Host "Force : `$Force"

# Créer un fichier de sortie pour vérifier que le script a été exécuté
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

Write-Host "Mode GRAN exécuté avec les paramètres suivants :"
Write-Host "FilePath : `$FilePath"
Write-Host "TaskIdentifier : `$TaskIdentifier"
Write-Host "Force : `$Force"

# Créer un fichier de sortie pour vérifier que le script a été exécuté
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

        # Supprimer les scripts de mode simulés
        $mockCheckModePath = Join-Path -Path $PSScriptRoot -ChildPath "mock-check-mode.ps1"
        if (Test-Path -Path $mockCheckModePath) {
            Remove-Item -Path $mockCheckModePath -Force
        }

        $mockGranModePath = Join-Path -Path $PSScriptRoot -ChildPath "mock-gran-mode.ps1"
        if (Test-Path -Path $mockGranModePath) {
            Remove-Item -Path $mockGranModePath -Force
        }
    }

    Context "Exécution des modes via le mode MANAGER" {
        BeforeEach {
            # Supprimer les fichiers de sortie des tests précédents
            $checkOutputPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\check-mode-output.txt"
            if (Test-Path -Path $checkOutputPath) {
                Remove-Item -Path $checkOutputPath -Force
            }

            $granOutputPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\gran-mode-output.txt"
            if (Test-Path -Path $granOutputPath) {
                Remove-Item -Path $granOutputPath -Force
            }
        }

        It "Devrait exécuter le mode CHECK via le mode MANAGER" {
            # Exécuter le mode CHECK via le mode MANAGER
            $tempConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\config.json"
            & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath

            # Vérifier que le fichier de sortie du mode CHECK a été créé
            $checkOutputPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\check-mode-output.txt"
            Test-Path -Path $checkOutputPath | Should -Be $true

            # Vérifier le contenu du fichier de sortie
            $checkOutput = Get-Content -Path $checkOutputPath -Raw
            $checkOutput | Should -Match "FilePath : $([regex]::Escape($testRoadmapPath))"
            $checkOutput | Should -Match "TaskIdentifier : 1.2.3"
        }

        It "Devrait exécuter le mode GRAN via le mode MANAGER" {
            # Exécuter le mode GRAN via le mode MANAGER
            $tempConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\config.json"
            & $scriptPath -Mode "GRAN" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath

            # Vérifier que le fichier de sortie du mode GRAN a été créé
            $granOutputPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\gran-mode-output.txt"
            Test-Path -Path $granOutputPath | Should -Be $true

            # Vérifier le contenu du fichier de sortie
            $granOutput = Get-Content -Path $granOutputPath -Raw
            $granOutput | Should -Match "FilePath : $([regex]::Escape($testRoadmapPath))"
            $granOutput | Should -Match "TaskIdentifier : 1.2.3"
        }

        It "Devrait exécuter une chaîne de modes via le mode MANAGER" {
            # Exécuter une chaîne de modes via le mode MANAGER
            $tempConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\config.json"
            & $scriptPath -Chain "GRAN,CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath

            # Vérifier que les fichiers de sortie des deux modes ont été créés
            $granOutputPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\gran-mode-output.txt"
            Test-Path -Path $granOutputPath | Should -Be $true

            $checkOutputPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\check-mode-output.txt"
            Test-Path -Path $checkOutputPath | Should -Be $true

            # Vérifier le contenu des fichiers de sortie
            $granOutput = Get-Content -Path $granOutputPath -Raw
            $granOutput | Should -Match "FilePath : $([regex]::Escape($testRoadmapPath))"
            $granOutput | Should -Match "TaskIdentifier : 1.2.3"

            $checkOutput = Get-Content -Path $checkOutputPath -Raw
            $checkOutput | Should -Match "FilePath : $([regex]::Escape($testRoadmapPath))"
            $checkOutput | Should -Match "TaskIdentifier : 1.2.3"
        }
    }
}

# Exécuter les tests
Invoke-Pester -Path $PSScriptRoot
