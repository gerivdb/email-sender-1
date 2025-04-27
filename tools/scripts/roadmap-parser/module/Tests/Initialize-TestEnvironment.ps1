<#
.SYNOPSIS
    Configure l'environnement de test pour le module RoadmapParser.

.DESCRIPTION
    Ce script configure l'environnement de test pour le module RoadmapParser en créant
    les répertoires et fichiers nécessaires, et en définissant les variables globales
    utilisées par les tests.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-05-15
#>

# Définir les chemins de base
$script:TestRoot = Join-Path -Path $env:TEMP -ChildPath "RoadmapParserTests"
$script:TestDataDir = Join-Path -Path $script:TestRoot -ChildPath "Data"
$script:TestConfigDir = Join-Path -Path $script:TestRoot -ChildPath "Config"
$script:TestLogDir = Join-Path -Path $script:TestRoot -ChildPath "Logs"
$script:TestOutputDir = Join-Path -Path $script:TestRoot -ChildPath "Output"
$script:TestReportDir = Join-Path -Path $script:TestRoot -ChildPath "Reports"

# Créer les répertoires de test
function Initialize-TestDirectories {
    [CmdletBinding()]
    param()

    # Créer les répertoires s'ils n'existent pas
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
            Write-Verbose "Répertoire créé: $dir"
        } else {
            Write-Verbose "Répertoire existant: $dir"
        }
    }
}

# Nettoyer les répertoires de test
function Clear-TestDirectories {
    [CmdletBinding()]
    param()

    # Nettoyer les répertoires
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
            Write-Verbose "Répertoire nettoyé: $dir"
        }
    }
}

# Créer des fichiers de test
function Initialize-TestFiles {
    [CmdletBinding()]
    param()

    # Créer un fichier de configuration de test
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
    Write-Verbose "Fichier de configuration créé: $configFile"

    # Créer un fichier de données de test
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
    Write-Verbose "Fichier de données créé: $dataFile"

    # Créer un fichier de roadmap de test
    $roadmapFile = Join-Path -Path $script:TestDataDir -ChildPath "test-roadmap.md"
    $roadmapContent = @"
# Roadmap de test

## Section 1
- [ ] Tâche 1
  - [ ] Sous-tâche 1.1
  - [ ] Sous-tâche 1.2
- [ ] Tâche 2
  - [ ] Sous-tâche 2.1
  - [ ] Sous-tâche 2.2

## Section 2
- [ ] Tâche 3
  - [ ] Sous-tâche 3.1
  - [ ] Sous-tâche 3.2
- [ ] Tâche 4
  - [ ] Sous-tâche 4.1
  - [ ] Sous-tâche 4.2
"@
    Set-Content -Path $roadmapFile -Value $roadmapContent -Force
    Write-Verbose "Fichier de roadmap créé: $roadmapFile"
}

# Fonction principale pour initialiser l'environnement de test
function Initialize-TestEnvironment {
    [CmdletBinding()]
    param(
        [switch]$Clean
    )

    Write-Host "Initialisation de l'environnement de test..."

    # Nettoyer les répertoires si demandé
    if ($Clean) {
        Write-Host "Nettoyage des répertoires de test..."
        Clear-TestDirectories
    }

    # Créer les répertoires
    Write-Host "Création des répertoires de test..."
    Initialize-TestDirectories

    # Créer les fichiers de test
    Write-Host "Création des fichiers de test..."
    Initialize-TestFiles

    # Définir les variables globales pour les tests
    $Global:TestRoot = $script:TestRoot
    $Global:TestDataDir = $script:TestDataDir
    $Global:TestConfigDir = $script:TestConfigDir
    $Global:TestLogDir = $script:TestLogDir
    $Global:TestOutputDir = $script:TestOutputDir
    $Global:TestReportDir = $script:TestReportDir

    Write-Host "Environnement de test initialisé avec succès."
    Write-Host "Répertoire racine des tests: $script:TestRoot"
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-TestEnvironment, Clear-TestDirectories
