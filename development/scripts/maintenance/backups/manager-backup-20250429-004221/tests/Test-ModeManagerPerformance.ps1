<#
.SYNOPSIS
    Tests de performance pour le script mode-manager.ps1.

.DESCRIPTION
    Ce script contient des tests de performance pour mesurer les performances du mode MANAGER.
    Il mesure le temps d'exÃ©cution et la consommation de mÃ©moire du mode MANAGER.

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

# Fonction pour mesurer le temps d'exÃ©cution
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

# Fonction pour mesurer la consommation de mÃ©moire
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

# DÃ©finir les tests
Describe "Mode Manager Performance Tests" {
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

# Simuler un traitement lÃ©ger
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

# Simuler un traitement lÃ©ger
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

    Context "Temps d'exÃ©cution" {
        It "Devrait mesurer le temps d'exÃ©cution du mode MANAGER avec -ListModes" {
            $executionTime = Measure-ExecutionTime -ScriptBlock {
                & $scriptPath -ListModes
            }
            Write-Host "Temps d'exÃ©cution du mode MANAGER avec -ListModes : $executionTime ms"
            $executionTime | Should -BeLessThan 1000
        }

        It "Devrait mesurer le temps d'exÃ©cution du mode MANAGER avec -ShowConfig" {
            $tempConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\config.json"
            $executionTime = Measure-ExecutionTime -ScriptBlock {
                & $scriptPath -ShowConfig -ConfigPath $tempConfigPath
            }
            Write-Host "Temps d'exÃ©cution du mode MANAGER avec -ShowConfig : $executionTime ms"
            $executionTime | Should -BeLessThan 1000
        }

        It "Devrait mesurer le temps d'exÃ©cution du mode MANAGER avec -Mode CHECK" {
            $tempConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\config.json"
            $executionTime = Measure-ExecutionTime -ScriptBlock {
                & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath
            }
            Write-Host "Temps d'exÃ©cution du mode MANAGER avec -Mode CHECK : $executionTime ms"
            $executionTime | Should -BeLessThan 1000
        }

        It "Devrait mesurer le temps d'exÃ©cution du mode MANAGER avec -Chain" {
            $tempConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\config.json"
            $executionTime = Measure-ExecutionTime -ScriptBlock {
                & $scriptPath -Chain "GRAN,CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath
            }
            Write-Host "Temps d'exÃ©cution du mode MANAGER avec -Chain : $executionTime ms"
            $executionTime | Should -BeLessThan 2000
        }
    }

    Context "Consommation de mÃ©moire" {
        It "Devrait mesurer la consommation de mÃ©moire du mode MANAGER avec -ListModes" {
            $memoryUsage = Measure-MemoryUsage -ScriptBlock {
                & $scriptPath -ListModes
            }
            Write-Host "Consommation de mÃ©moire du mode MANAGER avec -ListModes : $memoryUsage octets"
            $memoryUsage | Should -BeLessThan 10MB
        }

        It "Devrait mesurer la consommation de mÃ©moire du mode MANAGER avec -ShowConfig" {
            $tempConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\config.json"
            $memoryUsage = Measure-MemoryUsage -ScriptBlock {
                & $scriptPath -ShowConfig -ConfigPath $tempConfigPath
            }
            Write-Host "Consommation de mÃ©moire du mode MANAGER avec -ShowConfig : $memoryUsage octets"
            $memoryUsage | Should -BeLessThan 10MB
        }

        It "Devrait mesurer la consommation de mÃ©moire du mode MANAGER avec -Mode CHECK" {
            $tempConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\config.json"
            $memoryUsage = Measure-MemoryUsage -ScriptBlock {
                & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath
            }
            Write-Host "Consommation de mÃ©moire du mode MANAGER avec -Mode CHECK : $memoryUsage octets"
            $memoryUsage | Should -BeLessThan 10MB
        }

        It "Devrait mesurer la consommation de mÃ©moire du mode MANAGER avec -Chain" {
            $tempConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "temp\config.json"
            $memoryUsage = Measure-MemoryUsage -ScriptBlock {
                & $scriptPath -Chain "GRAN,CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath
            }
            Write-Host "Consommation de mÃ©moire du mode MANAGER avec -Chain : $memoryUsage octets"
            $memoryUsage | Should -BeLessThan 10MB
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Path $PSScriptRoot
