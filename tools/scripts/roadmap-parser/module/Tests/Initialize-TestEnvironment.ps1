<#
.SYNOPSIS
    Configure l'environnement de test pour le module RoadmapParser.

.DESCRIPTION
    Ce script configure l'environnement de test pour le module RoadmapParser en crÃ©ant
    les rÃ©pertoires et fichiers nÃ©cessaires, et en dÃ©finissant les variables globales
    utilisÃ©es par les tests.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-05-15
#>

# DÃ©finir les chemins de base
$script:TestRoot = Join-Path -Path $env:TEMP -ChildPath "RoadmapParserTests"
$script:TestDataDir = Join-Path -Path $script:TestRoot -ChildPath "Data"
$script:TestConfigDir = Join-Path -Path $script:TestRoot -ChildPath "Config"
$script:TestLogDir = Join-Path -Path $script:TestRoot -ChildPath "Logs"
$script:TestOutputDir = Join-Path -Path $script:TestRoot -ChildPath "Output"
$script:TestReportDir = Join-Path -Path $script:TestRoot -ChildPath "Reports"

# CrÃ©er les rÃ©pertoires de test
function Initialize-TestDirectories {
    [CmdletBinding()]
    param()

    # CrÃ©er les rÃ©pertoires s'ils n'existent pas
    $directories = @(
        $script:TestRoot,
        $script:TestDataDir,
        $script:TestConfigDir,
        $script:TestLogDir,
        $script:TestOutputDir,
        $script:TestReportDir
    )

    foreach ($dir in $directories) {
        if (-not (Test-Path -Path $dir -PathType Container)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-Verbose "RÃ©pertoire crÃ©Ã©: $dir"
        } else {
            Write-Verbose "RÃ©pertoire existant: $dir"
        }
    }
}

# Nettoyer les rÃ©pertoires de test
function Clear-TestDirectories {
    [CmdletBinding()]
    param()

    # Nettoyer les rÃ©pertoires
    $directories = @(
        $script:TestDataDir,
        $script:TestConfigDir,
        $script:TestLogDir,
        $script:TestOutputDir,
        $script:TestReportDir
    )

    foreach ($dir in $directories) {
        if (Test-Path -Path $dir -PathType Container) {
            Get-ChildItem -Path $dir -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Write-Verbose "RÃ©pertoire nettoyÃ©: $dir"
        }
    }
}

# CrÃ©er des fichiers de test
function Initialize-TestFiles {
    [CmdletBinding()]
    param()

    # CrÃ©er un fichier de configuration de test
    $configFile = Join-Path -Path $script:TestConfigDir -ChildPath "test-config.json"
    $config = @{
        LogLevel = "Debug"
        LogFile = Join-Path -Path $script:TestLogDir -ChildPath "test.log"
        ConsoleOutput = $true
        FileOutput = $true
        MaxLogSize = 1MB
        EnableLogRotation = $true
        MaxLogFiles = 5
    }
    $config | ConvertTo-Json | Set-Content -Path $configFile -Force
    Write-Verbose "Fichier de configuration crÃ©Ã©: $configFile"

    # CrÃ©er un fichier de donnÃ©es de test
    $dataFile = Join-Path -Path $script:TestDataDir -ChildPath "test-data.json"
    $data = @(
        [PSCustomObject]@{
            ID = 1
            Name = "Task 1"
            Status = "Completed"
            Priority = "High"
            DueDate = (Get-Date).AddDays(5).ToString("yyyy-MM-dd")
        },
        [PSCustomObject]@{
            ID = 2
            Name = "Task 2"
            Status = "In Progress"
            Priority = "Medium"
            DueDate = (Get-Date).AddDays(10).ToString("yyyy-MM-dd")
        },
        [PSCustomObject]@{
            ID = 3
            Name = "Task 3"
            Status = "Not Started"
            Priority = "Low"
            DueDate = (Get-Date).AddDays(15).ToString("yyyy-MM-dd")
        }
    )
    $data | ConvertTo-Json | Set-Content -Path $dataFile -Force
    Write-Verbose "Fichier de donnÃ©es crÃ©Ã©: $dataFile"

    # CrÃ©er un fichier de roadmap de test
    $roadmapFile = Join-Path -Path $script:TestDataDir -ChildPath "test-roadmap.md"
    $roadmapContent = @"
# Roadmap de test

## Section 1
- [ ] TÃ¢che 1
  - [ ] Sous-tÃ¢che 1.1
  - [ ] Sous-tÃ¢che 1.2
- [ ] TÃ¢che 2
  - [ ] Sous-tÃ¢che 2.1
  - [ ] Sous-tÃ¢che 2.2

## Section 2
- [ ] TÃ¢che 3
  - [ ] Sous-tÃ¢che 3.1
  - [ ] Sous-tÃ¢che 3.2
- [ ] TÃ¢che 4
  - [ ] Sous-tÃ¢che 4.1
  - [ ] Sous-tÃ¢che 4.2
"@
    Set-Content -Path $roadmapFile -Value $roadmapContent -Force
    Write-Verbose "Fichier de roadmap crÃ©Ã©: $roadmapFile"
}

# Fonction principale pour initialiser l'environnement de test
function Initialize-TestEnvironment {
    [CmdletBinding()]
    param(
        [switch]$Clean
    )

    Write-Host "Initialisation de l'environnement de test..."

    # Nettoyer les rÃ©pertoires si demandÃ©
    if ($Clean) {
        Write-Host "Nettoyage des rÃ©pertoires de test..."
        Clear-TestDirectories
    }

    # CrÃ©er les rÃ©pertoires
    Write-Host "CrÃ©ation des rÃ©pertoires de test..."
    Initialize-TestDirectories

    # CrÃ©er les fichiers de test
    Write-Host "CrÃ©ation des fichiers de test..."
    Initialize-TestFiles

    # DÃ©finir les variables globales pour les tests
    $Global:TestRoot = $script:TestRoot
    $Global:TestDataDir = $script:TestDataDir
    $Global:TestConfigDir = $script:TestConfigDir
    $Global:TestLogDir = $script:TestLogDir
    $Global:TestOutputDir = $script:TestOutputDir
    $Global:TestReportDir = $script:TestReportDir

    Write-Host "Environnement de test initialisÃ© avec succÃ¨s."
    Write-Host "RÃ©pertoire racine des tests: $script:TestRoot"
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-TestEnvironment, Clear-TestDirectories
