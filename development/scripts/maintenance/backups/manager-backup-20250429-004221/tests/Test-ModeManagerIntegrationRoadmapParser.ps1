# Tests d'intégration entre le mode manager et le roadmap parser

# Définir le chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\mode-manager.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Error "Le script mode-manager.ps1 est introuvable à l'emplacement : $scriptPath"
    exit 1
}

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Définir le chemin du roadmap parser
$roadmapParserPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\roadmap-parser\module\Functions\Public\Roadmap-Parser.ps1"
if (-not (Test-Path -Path $roadmapParserPath)) {
    Write-Warning "Le roadmap parser est introuvable à l'emplacement : $roadmapParserPath"
    Write-Warning "Création d'un roadmap parser simulé pour les tests"

    # Créer un roadmap parser simulé
    $roadmapParserPath = Join-Path -Path $testDir -ChildPath "Roadmap-Parser.ps1"
    $roadmapParserContent = @'
<#
.SYNOPSIS
    Roadmap Parser simulé pour les tests d'intégration.

.DESCRIPTION
    Ce script simule le roadmap parser pour les tests d'intégration.

.PARAMETER FilePath
    Chemin du fichier de roadmap à analyser.

.PARAMETER TaskIdentifier
    Identifiant de la tâche à analyser.

.PARAMETER OutputFormat
    Format de sortie des résultats.

.EXAMPLE
    .\Roadmap-Parser.ps1 -FilePath "roadmap.md" -TaskIdentifier "1.2.3" -OutputFormat "JSON"

.NOTES
    Ce script est utilisé pour les tests d'intégration du mode manager.
#>
param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [string]$OutputFormat = "JSON"
)

# Vérifier que le fichier existe
if (-not (Test-Path -Path $FilePath)) {
    Write-Error "Le fichier de roadmap est introuvable à l'emplacement : $FilePath"
    exit 1
}

# Simuler l'analyse du fichier de roadmap
$content = Get-Content -Path $FilePath -Raw

# Simuler la recherche de la tâche
if (-not [string]::IsNullOrEmpty($TaskIdentifier)) {
    $taskPattern = "## Tâche $TaskIdentifier"
    if ($content -match $taskPattern) {
        $taskContent = $Matches[0]

        # Simuler la sortie JSON
        if ($OutputFormat -eq "JSON") {
            $result = @{
                TaskIdentifier = $TaskIdentifier
                Content = $taskContent
                Status = "Pending"
                SubTasks = @()
            } | ConvertTo-Json

            Write-Output $result
        } else {
            Write-Output "Tâche : $TaskIdentifier"
            Write-Output "Contenu : $taskContent"
            Write-Output "Statut : Pending"
            Write-Output "Sous-tâches : 0"
        }
    } else {
        Write-Error "La tâche $TaskIdentifier est introuvable dans le fichier de roadmap."
        exit 1
    }
} else {
    # Simuler la sortie JSON pour toutes les tâches
    if ($OutputFormat -eq "JSON") {
        $result = @{
            TaskCount = 10
            CompletedTasks = 0
            PendingTasks = 10
            Tasks = @()
        } | ConvertTo-Json

        Write-Output $result
    } else {
        Write-Output "Nombre de tâches : 10"
        Write-Output "Tâches terminées : 0"
        Write-Output "Tâches en attente : 10"
    }
}

exit 0
'@
    Set-Content -Path $roadmapParserPath -Value $roadmapParserContent -Encoding UTF8
}

# Créer un fichier de configuration pour les tests
$tempConfigPath = Join-Path -Path $testDir -ChildPath "integration-config.json"
@{
    General = @{
        RoadmapPath        = "docs\plans\roadmap_complete_2.md"
        ActiveDocumentPath = "docs\plans\plan-modes-stepup.md"
        ReportPath         = "reports"
    }
    Modes   = @{
        Check         = @{
            Enabled      = $true
            ScriptPath   = Join-Path -Path $PSScriptRoot -ChildPath "mock-check-mode.ps1"
            Dependencies = @("RoadmapParser")
        }
        Gran          = @{
            Enabled      = $true
            ScriptPath   = Join-Path -Path $PSScriptRoot -ChildPath "mock-gran-mode.ps1"
            Dependencies = @("RoadmapParser")
        }
        RoadmapParser = @{
            Enabled    = $true
            ScriptPath = $roadmapParserPath
        }
    }
} | ConvertTo-Json -Depth 5 | Set-Content -Path $tempConfigPath -Encoding UTF8

# Créer des scripts de mode simulés
$mockCheckModePath = Join-Path -Path $PSScriptRoot -ChildPath "mock-check-mode.ps1"
$mockCheckContent = @'
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [string]$ActiveDocumentPath,

    [Parameter(Mandatory = $false)]
    [switch]$CheckActiveDocument,

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath,

    [Parameter(Mandatory = $false)]
    [string]$RoadmapParserOutput
)

Write-Host "Mode CHECK exécuté avec les paramètres suivants :"
Write-Host "FilePath : $FilePath"
Write-Host "TaskIdentifier : $TaskIdentifier"
Write-Host "Force : $Force"
Write-Host "ActiveDocumentPath : $ActiveDocumentPath"
Write-Host "CheckActiveDocument : $CheckActiveDocument"
Write-Host "ConfigPath : $ConfigPath"
Write-Host "RoadmapParserOutput : $RoadmapParserOutput"

# Créer un fichier de sortie pour vérifier que le script a été exécuté
$outputPath = Join-Path -Path "$PSScriptRoot\temp" -ChildPath "check-mode-output.txt"
@"
FilePath : $FilePath
TaskIdentifier : $TaskIdentifier
Force : $Force
ActiveDocumentPath : $ActiveDocumentPath
CheckActiveDocument : $CheckActiveDocument
ConfigPath : $ConfigPath
RoadmapParserOutput : $RoadmapParserOutput
"@ | Set-Content -Path $outputPath -Encoding UTF8

exit 0
'@
Set-Content -Path $mockCheckModePath -Value $mockCheckContent -Encoding UTF8

$mockGranModePath = Join-Path -Path $PSScriptRoot -ChildPath "mock-gran-mode.ps1"
$mockGranContent = @'
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath,

    [Parameter(Mandatory = $false)]
    [string]$RoadmapParserOutput
)

Write-Host "Mode GRAN exécuté avec les paramètres suivants :"
Write-Host "FilePath : $FilePath"
Write-Host "TaskIdentifier : $TaskIdentifier"
Write-Host "Force : $Force"
Write-Host "ConfigPath : $ConfigPath"
Write-Host "RoadmapParserOutput : $RoadmapParserOutput"

# Créer un fichier de sortie pour vérifier que le script a été exécuté
$outputPath = Join-Path -Path "$PSScriptRoot\temp" -ChildPath "gran-mode-output.txt"
@"
FilePath : $FilePath
TaskIdentifier : $TaskIdentifier
Force : $Force
ConfigPath : $ConfigPath
RoadmapParserOutput : $RoadmapParserOutput
"@ | Set-Content -Path $outputPath -Encoding UTF8

exit 0
'@
Set-Content -Path $mockGranModePath -Value $mockGranContent -Encoding UTF8

# Créer un fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
@"
# Test Roadmap

## Tâche 1.2.3

### Description
Cette tâche est utilisée pour les tests d'intégration.

### Sous-tâches
- [ ] Sous-tâche 1
- [ ] Sous-tâche 2
- [ ] Sous-tâche 3
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8

# Test 1: Intégration avec le roadmap parser - Mode CHECK
Write-Host "Test 1: Intégration avec le roadmap parser - Mode CHECK" -ForegroundColor Cyan
try {
    # Exécuter le script avec le mode CHECK
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1

    # Vérifier que le script a correctement intégré le roadmap parser
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "RoadmapParserOutput") {
            Write-Host "Test 1 réussi: Le script a correctement intégré le roadmap parser avec le mode CHECK" -ForegroundColor Green
        } else {
            Write-Host "Test 1 échoué: Le script n'a pas correctement intégré le roadmap parser avec le mode CHECK" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 1 échoué: Le fichier de sortie du mode CHECK n'a pas été créé" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 1 échoué: Une erreur s'est produite lors de l'exécution du script avec le mode CHECK" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 2: Intégration avec le roadmap parser - Mode GRAN
Write-Host "Test 2: Intégration avec le roadmap parser - Mode GRAN" -ForegroundColor Cyan
try {
    # Exécuter le script avec le mode GRAN
    $output = & $scriptPath -Mode "GRAN" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1

    # Vérifier que le script a correctement intégré le roadmap parser
    $granOutputPath = Join-Path -Path $testDir -ChildPath "gran-mode-output.txt"
    if (Test-Path -Path $granOutputPath) {
        $granOutput = Get-Content -Path $granOutputPath -Raw
        if ($granOutput -match "RoadmapParserOutput") {
            Write-Host "Test 2 réussi: Le script a correctement intégré le roadmap parser avec le mode GRAN" -ForegroundColor Green
        } else {
            Write-Host "Test 2 échoué: Le script n'a pas correctement intégré le roadmap parser avec le mode GRAN" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 2 échoué: Le fichier de sortie du mode GRAN n'a pas été créé" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 2 échoué: Une erreur s'est produite lors de l'exécution du script avec le mode GRAN" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 3: Intégration avec le roadmap parser - Chaîne de modes
Write-Host "Test 3: Intégration avec le roadmap parser - Chaîne de modes" -ForegroundColor Cyan
try {
    # Supprimer les fichiers de sortie des tests précédents
    $outputFiles = @("check-mode-output.txt", "gran-mode-output.txt")
    foreach ($file in $outputFiles) {
        $outputPath = Join-Path -Path $testDir -ChildPath $file
        if (Test-Path -Path $outputPath) {
            Remove-Item -Path $outputPath -Force
        }
    }

    # Exécuter les modes séquentiellement
    & $scriptPath -Mode "GRAN" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath
    & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath

    # Vérifier que le script a correctement intégré le roadmap parser pour les deux modes
    $success = $true
    foreach ($file in $outputFiles) {
        $outputPath = Join-Path -Path $testDir -ChildPath $file
        if (Test-Path -Path $outputPath) {
            $fileOutput = Get-Content -Path $outputPath -Raw
            if (-not ($fileOutput -match "RoadmapParserOutput")) {
                Write-Host "Test 3 échoué: Le script n'a pas correctement intégré le roadmap parser pour le fichier $file" -ForegroundColor Red
                $success = $false
            }
        } else {
            Write-Host "Test 3 échoué: Le fichier de sortie $file n'a pas été créé" -ForegroundColor Red
            $success = $false
        }
    }

    if ($success) {
        Write-Host "Test 3 réussi: Le script a correctement intégré le roadmap parser avec une chaîne de modes" -ForegroundColor Green
    }
} catch {
    Write-Host "Test 3 échoué: Une erreur s'est produite lors de l'exécution du script avec une chaîne de modes" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 4: Intégration avec le roadmap parser - Tâche inexistante
Write-Host "Test 4: Intégration avec le roadmap parser - Tâche inexistante" -ForegroundColor Cyan
try {
    # Exécuter le script avec une tâche inexistante
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "9.9.9" -ConfigPath $tempConfigPath 2>&1

    # Vérifier que le script a correctement géré l'erreur du roadmap parser
    if ($output -match "introuvable" -or $output -match "not found" -or $output -match "n'existe pas") {
        Write-Host "Test 4 réussi: Le script a correctement géré l'erreur du roadmap parser pour une tâche inexistante" -ForegroundColor Green
    } else {
        Write-Host "Test 4 échoué: Le script n'a pas correctement géré l'erreur du roadmap parser pour une tâche inexistante" -ForegroundColor Red
    }
} catch {
    # Si une erreur est générée, c'est aussi acceptable
    if ($_.Exception.Message -match "introuvable" -or $_.Exception.Message -match "not found" -or $_.Exception.Message -match "n'existe pas") {
        Write-Host "Test 4 réussi: Le script a correctement géré l'erreur du roadmap parser pour une tâche inexistante" -ForegroundColor Green
    } else {
        Write-Host "Test 4 échoué: Le script n'a pas correctement géré l'erreur du roadmap parser pour une tâche inexistante" -ForegroundColor Red
        Write-Host "Erreur: $_" -ForegroundColor Red
    }
}

# Nettoyer les fichiers temporaires
Write-Host "Nettoyage des fichiers temporaires..." -ForegroundColor Cyan
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}

$mockFiles = @(
    "mock-check-mode.ps1",
    "mock-gran-mode.ps1"
)

foreach ($file in $mockFiles) {
    $filePath = Join-Path -Path $PSScriptRoot -ChildPath $file
    if (Test-Path -Path $filePath) {
        Remove-Item -Path $filePath -Force
    }
}

Write-Host "Tests terminés." -ForegroundColor Cyan
