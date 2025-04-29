<#
.SYNOPSIS
    Tests de performance pour le script mode-manager.ps1.

.DESCRIPTION
    Ce script contient des tests de performance pour mesurer les performances du mode MANAGER.
    Il mesure le temps d'exécution et la consommation de mémoire du mode MANAGER.

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

# Fonction pour mesurer le temps d'exécution
function Measure-ExecutionTime {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    & $ScriptBlock
    $stopwatch.Stop()
    return $stopwatch.ElapsedMilliseconds
}

# Fonction pour mesurer la consommation de mémoire
function Measure-MemoryUsage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )

    $initialMemory = [System.GC]::GetTotalMemory($true)
    & $ScriptBlock
    $finalMemory = [System.GC]::GetTotalMemory($true)
    return $finalMemory - $initialMemory
}

# Définir les tests
Describe "Mode Manager Performance Tests" {
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

# Simuler un traitement léger
Start-Sleep -Milliseconds 100

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

# Simuler un traitement léger
Start-Sleep -Milliseconds 100

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

    Context "Temps d'exécution" {
        It "Devrait mesurer le temps d'exécution du mode MANAGER avec -ListModes" {
            $executionTime = Measure-ExecutionTime -ScriptBlock {
                & $scriptPath -ListModes
            }
            Write-Host "Temps d'exécution du mode MANAGER avec -ListModes : $executionTime ms"
            $executionTime | Should -BeLessThan 1000
        }

        It "Devrait mesurer le temps d'exécution du mode MANAGER avec -ShowConfig" {
            $tempConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\config.json"
            $executionTime = Measure-ExecutionTime -ScriptBlock {
                & $scriptPath -ShowConfig -ConfigPath $tempConfigPath
            }
            Write-Host "Temps d'exécution du mode MANAGER avec -ShowConfig : $executionTime ms"
            $executionTime | Should -BeLessThan 1000
        }

        It "Devrait mesurer le temps d'exécution du mode MANAGER avec -Mode CHECK" {
            $tempConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\config.json"
            $executionTime = Measure-ExecutionTime -ScriptBlock {
                & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath
            }
            Write-Host "Temps d'exécution du mode MANAGER avec -Mode CHECK : $executionTime ms"
            $executionTime | Should -BeLessThan 1000
        }

        It "Devrait mesurer le temps d'exécution du mode MANAGER avec -Chain" {
            $tempConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\config.json"
            $executionTime = Measure-ExecutionTime -ScriptBlock {
                & $scriptPath -Chain "GRAN,CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath
            }
            Write-Host "Temps d'exécution du mode MANAGER avec -Chain : $executionTime ms"
            $executionTime | Should -BeLessThan 2000
        }
    }

    Context "Consommation de mémoire" {
        It "Devrait mesurer la consommation de mémoire du mode MANAGER avec -ListModes" {
            $memoryUsage = Measure-MemoryUsage -ScriptBlock {
                & $scriptPath -ListModes
            }
            Write-Host "Consommation de mémoire du mode MANAGER avec -ListModes : $memoryUsage octets"
            $memoryUsage | Should -BeLessThan 10MB
        }

        It "Devrait mesurer la consommation de mémoire du mode MANAGER avec -ShowConfig" {
            $tempConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\config.json"
            $memoryUsage = Measure-MemoryUsage -ScriptBlock {
                & $scriptPath -ShowConfig -ConfigPath $tempConfigPath
            }
            Write-Host "Consommation de mémoire du mode MANAGER avec -ShowConfig : $memoryUsage octets"
            $memoryUsage | Should -BeLessThan 10MB
        }

        It "Devrait mesurer la consommation de mémoire du mode MANAGER avec -Mode CHECK" {
            $tempConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\config.json"
            $memoryUsage = Measure-MemoryUsage -ScriptBlock {
                & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath
            }
            Write-Host "Consommation de mémoire du mode MANAGER avec -Mode CHECK : $memoryUsage octets"
            $memoryUsage | Should -BeLessThan 10MB
        }

        It "Devrait mesurer la consommation de mémoire du mode MANAGER avec -Chain" {
            $tempConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\config.json"
            $memoryUsage = Measure-MemoryUsage -ScriptBlock {
                & $scriptPath -Chain "GRAN,CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath
            }
            Write-Host "Consommation de mémoire du mode MANAGER avec -Chain : $memoryUsage octets"
            $memoryUsage | Should -BeLessThan 10MB
        }
    }
}

# Exécuter les tests
Invoke-Pester -Path $PSScriptRoot
