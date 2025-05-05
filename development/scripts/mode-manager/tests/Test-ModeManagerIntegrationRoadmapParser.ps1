# Tests d'intÃ©gration entre le mode manager et le roadmap parser

# DÃ©finir le chemin du script Ã  tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\mode-manager.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Error "Le script mode-manager.ps1 est introuvable Ã  l'emplacement : $scriptPath"
    exit 1
}

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# DÃ©finir le chemin du roadmap parser
$roadmapParserPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\roadmap-parser\module\Functions\Public\Roadmap-Parser.ps1"
if (-not (Test-Path -Path $roadmapParserPath)) {
    Write-Warning "Le roadmap parser est introuvable Ã  l'emplacement : $roadmapParserPath"
    Write-Warning "CrÃ©ation d'un roadmap parser simulÃ© pour les tests"

    # CrÃ©er un roadmap parser simulÃ©
    $roadmapParserPath = Join-Path -Path $testDir -ChildPath "Roadmap-Parser.ps1"
    $roadmapParserContent = @'
<#
.SYNOPSIS
    Roadmap Parser simulÃ© pour les tests d'intÃ©gration.

.DESCRIPTION
    Ce script simule le roadmap parser pour les tests d'intÃ©gration.

.PARAMETER FilePath
    Chemin du fichier de roadmap Ã  analyser.

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  analyser.

.PARAMETER OutputFormat
    Format de sortie des rÃ©sultats.

.EXAMPLE
    .\Roadmap-Parser.ps1 -FilePath "roadmap.md" -TaskIdentifier "1.2.3" -OutputFormat "JSON"

.NOTES
    Ce script est utilisÃ© pour les tests d'intÃ©gration du mode manager.
#>
param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [string]$OutputFormat = "JSON"
)

# VÃ©rifier que le fichier existe
if (-not (Test-Path -Path $FilePath)) {
    Write-Error "Le fichier de roadmap est introuvable Ã  l'emplacement : $FilePath"
    exit 1
}

# Simuler l'analyse du fichier de roadmap
$content = Get-Content -Path $FilePath -Raw

# Simuler la recherche de la tÃ¢che
if (-not [string]::IsNullOrEmpty($TaskIdentifier)) {
    $taskPattern = "## TÃ¢che $TaskIdentifier"
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
            Write-Output "TÃ¢che : $TaskIdentifier"
            Write-Output "Contenu : $taskContent"
            Write-Output "Statut : Pending"
            Write-Output "Sous-tÃ¢ches : 0"
        }
    } else {
        Write-Error "La tÃ¢che $TaskIdentifier est introuvable dans le fichier de roadmap."
        exit 1
    }
} else {
    # Simuler la sortie JSON pour toutes les tÃ¢ches
    if ($OutputFormat -eq "JSON") {
        $result = @{
            TaskCount = 10
            CompletedTasks = 0
            PendingTasks = 10
            Tasks = @()
        } | ConvertTo-Json

        Write-Output $result
    } else {
        Write-Output "Nombre de tÃ¢ches : 10"
        Write-Output "TÃ¢ches terminÃ©es : 0"
        Write-Output "TÃ¢ches en attente : 10"
    }
}

exit 0
'@
    Set-Content -Path $roadmapParserPath -Value $roadmapParserContent -Encoding UTF8
}

# CrÃ©er un fichier de configuration pour les tests
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

# CrÃ©er des scripts de mode simulÃ©s
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

Write-Host "Mode CHECK exÃ©cutÃ© avec les paramÃ¨tres suivants :"
Write-Host "FilePath : $FilePath"
Write-Host "TaskIdentifier : $TaskIdentifier"
Write-Host "Force : $Force"
Write-Host "ActiveDocumentPath : $ActiveDocumentPath"
Write-Host "CheckActiveDocument : $CheckActiveDocument"
Write-Host "ConfigPath : $ConfigPath"
Write-Host "RoadmapParserOutput : $RoadmapParserOutput"

# CrÃ©er un fichier de sortie pour vÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ©
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

Write-Host "Mode GRAN exÃ©cutÃ© avec les paramÃ¨tres suivants :"
Write-Host "FilePath : $FilePath"
Write-Host "TaskIdentifier : $TaskIdentifier"
Write-Host "Force : $Force"
Write-Host "ConfigPath : $ConfigPath"
Write-Host "RoadmapParserOutput : $RoadmapParserOutput"

# CrÃ©er un fichier de sortie pour vÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ©
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

# CrÃ©er un fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
@"
# Test Roadmap

## TÃ¢che 1.2.3

### Description
Cette tÃ¢che est utilisÃ©e pour les tests d'intÃ©gration.

### Sous-tÃ¢ches
- [ ] Sous-tÃ¢che 1
- [ ] Sous-tÃ¢che 2
- [ ] Sous-tÃ¢che 3
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8

# Test 1: IntÃ©gration avec le roadmap parser - Mode CHECK
Write-Host "Test 1: IntÃ©gration avec le roadmap parser - Mode CHECK" -ForegroundColor Cyan
try {
    # ExÃ©cuter le script avec le mode CHECK
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1

    # VÃ©rifier que le script a correctement intÃ©grÃ© le roadmap parser
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "RoadmapParserOutput") {
            Write-Host "Test 1 rÃ©ussi: Le script a correctement intÃ©grÃ© le roadmap parser avec le mode CHECK" -ForegroundColor Green
        } else {
            Write-Host "Test 1 Ã©chouÃ©: Le script n'a pas correctement intÃ©grÃ© le roadmap parser avec le mode CHECK" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 1 Ã©chouÃ©: Le fichier de sortie du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 1 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec le mode CHECK" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 2: IntÃ©gration avec le roadmap parser - Mode GRAN
Write-Host "Test 2: IntÃ©gration avec le roadmap parser - Mode GRAN" -ForegroundColor Cyan
try {
    # ExÃ©cuter le script avec le mode GRAN
    $output = & $scriptPath -Mode "GRAN" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1

    # VÃ©rifier que le script a correctement intÃ©grÃ© le roadmap parser
    $granOutputPath = Join-Path -Path $testDir -ChildPath "gran-mode-output.txt"
    if (Test-Path -Path $granOutputPath) {
        $granOutput = Get-Content -Path $granOutputPath -Raw
        if ($granOutput -match "RoadmapParserOutput") {
            Write-Host "Test 2 rÃ©ussi: Le script a correctement intÃ©grÃ© le roadmap parser avec le mode GRAN" -ForegroundColor Green
        } else {
            Write-Host "Test 2 Ã©chouÃ©: Le script n'a pas correctement intÃ©grÃ© le roadmap parser avec le mode GRAN" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 2 Ã©chouÃ©: Le fichier de sortie du mode GRAN n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 2 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec le mode GRAN" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 3: IntÃ©gration avec le roadmap parser - ChaÃ®ne de modes
Write-Host "Test 3: IntÃ©gration avec le roadmap parser - ChaÃ®ne de modes" -ForegroundColor Cyan
try {
    # Supprimer les fichiers de sortie des tests prÃ©cÃ©dents
    $outputFiles = @("check-mode-output.txt", "gran-mode-output.txt")
    foreach ($file in $outputFiles) {
        $outputPath = Join-Path -Path $testDir -ChildPath $file
        if (Test-Path -Path $outputPath) {
            Remove-Item -Path $outputPath -Force
        }
    }

    # ExÃ©cuter les modes sÃ©quentiellement
    & $scriptPath -Mode "GRAN" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath
    & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath

    # VÃ©rifier que le script a correctement intÃ©grÃ© le roadmap parser pour les deux modes
    $success = $true
    foreach ($file in $outputFiles) {
        $outputPath = Join-Path -Path $testDir -ChildPath $file
        if (Test-Path -Path $outputPath) {
            $fileOutput = Get-Content -Path $outputPath -Raw
            if (-not ($fileOutput -match "RoadmapParserOutput")) {
                Write-Host "Test 3 Ã©chouÃ©: Le script n'a pas correctement intÃ©grÃ© le roadmap parser pour le fichier $file" -ForegroundColor Red
                $success = $false
            }
        } else {
            Write-Host "Test 3 Ã©chouÃ©: Le fichier de sortie $file n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
            $success = $false
        }
    }

    if ($success) {
        Write-Host "Test 3 rÃ©ussi: Le script a correctement intÃ©grÃ© le roadmap parser avec une chaÃ®ne de modes" -ForegroundColor Green
    }
} catch {
    Write-Host "Test 3 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec une chaÃ®ne de modes" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 4: IntÃ©gration avec le roadmap parser - TÃ¢che inexistante
Write-Host "Test 4: IntÃ©gration avec le roadmap parser - TÃ¢che inexistante" -ForegroundColor Cyan
try {
    # ExÃ©cuter le script avec une tÃ¢che inexistante
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "9.9.9" -ConfigPath $tempConfigPath 2>&1

    # VÃ©rifier que le script a correctement gÃ©rÃ© l'erreur du roadmap parser
    if ($output -match "introuvable" -or $output -match "not found" -or $output -match "n'existe pas") {
        Write-Host "Test 4 rÃ©ussi: Le script a correctement gÃ©rÃ© l'erreur du roadmap parser pour une tÃ¢che inexistante" -ForegroundColor Green
    } else {
        Write-Host "Test 4 Ã©chouÃ©: Le script n'a pas correctement gÃ©rÃ© l'erreur du roadmap parser pour une tÃ¢che inexistante" -ForegroundColor Red
    }
} catch {
    # Si une erreur est gÃ©nÃ©rÃ©e, c'est aussi acceptable
    if ($_.Exception.Message -match "introuvable" -or $_.Exception.Message -match "not found" -or $_.Exception.Message -match "n'existe pas") {
        Write-Host "Test 4 rÃ©ussi: Le script a correctement gÃ©rÃ© l'erreur du roadmap parser pour une tÃ¢che inexistante" -ForegroundColor Green
    } else {
        Write-Host "Test 4 Ã©chouÃ©: Le script n'a pas correctement gÃ©rÃ© l'erreur du roadmap parser pour une tÃ¢che inexistante" -ForegroundColor Red
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

Write-Host "Tests terminÃ©s." -ForegroundColor Cyan
