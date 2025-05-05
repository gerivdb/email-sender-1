# Tests d'intÃ©gration entre le mode manager et le gÃ©nÃ©rateur de rapports

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

# CrÃ©er un rÃ©pertoire pour les rapports
$reportsDir = Join-Path -Path $testDir -ChildPath "reports"
if (-not (Test-Path -Path $reportsDir)) {
    New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null
}

# DÃ©finir le chemin du gÃ©nÃ©rateur de rapports
$reportGeneratorPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\reporting\generate_reports.ps1"
if (-not (Test-Path -Path $reportGeneratorPath)) {
    Write-Warning "Le gÃ©nÃ©rateur de rapports est introuvable Ã  l'emplacement : $reportGeneratorPath"
    Write-Warning "CrÃ©ation d'un gÃ©nÃ©rateur de rapports simulÃ© pour les tests"
    
    # CrÃ©er un gÃ©nÃ©rateur de rapports simulÃ©
    $reportGeneratorPath = Join-Path -Path $testDir -ChildPath "generate_reports.ps1"
    $reportGeneratorContent = @'
<#
.SYNOPSIS
    GÃ©nÃ©rateur de rapports simulÃ© pour les tests d'intÃ©gration.

.DESCRIPTION
    Ce script simule le gÃ©nÃ©rateur de rapports pour les tests d'intÃ©gration.

.PARAMETER InputPath
    Chemin du fichier d'entrÃ©e pour le rapport.

.PARAMETER OutputPath
    Chemin du rÃ©pertoire de sortie pour le rapport.

.PARAMETER ReportType
    Type de rapport Ã  gÃ©nÃ©rer.

.PARAMETER ConfigPath
    Chemin du fichier de configuration.

.EXAMPLE
    .\generate_reports.ps1 -InputPath "input.json" -OutputPath "reports" -ReportType "HTML" -ConfigPath "config.json"

.NOTES
    Ce script est utilisÃ© pour les tests d'intÃ©gration du mode manager.
#>
param (
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [string]$ReportType = "HTML",

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath
)

# VÃ©rifier que le fichier d'entrÃ©e existe
if (-not (Test-Path -Path $InputPath)) {
    Write-Error "Le fichier d'entrÃ©e est introuvable Ã  l'emplacement : $InputPath"
    exit 1
}

# VÃ©rifier que le rÃ©pertoire de sortie existe
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Simuler la gÃ©nÃ©ration d'un rapport
$reportContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de test</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .summary { margin: 20px 0; padding: 10px; background-color: #f5f5f5; border-radius: 5px; }
        .passed { color: green; }
        .failed { color: red; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    <h1>Rapport de test</h1>
    <div class="summary">
        <p>Fichier d'entrÃ©e : $InputPath</p>
        <p>Type de rapport : $ReportType</p>
        <p>Configuration : $ConfigPath</p>
    </div>
    <h2>DÃ©tails</h2>
    <table>
        <tr>
            <th>Ã‰lÃ©ment</th>
            <th>Statut</th>
        </tr>
        <tr>
            <td>Ã‰lÃ©ment 1</td>
            <td class="passed">RÃ©ussi</td>
        </tr>
        <tr>
            <td>Ã‰lÃ©ment 2</td>
            <td class="passed">RÃ©ussi</td>
        </tr>
        <tr>
            <td>Ã‰lÃ©ment 3</td>
            <td class="passed">RÃ©ussi</td>
        </tr>
    </table>
</body>
</html>
"@

# GÃ©nÃ©rer le rapport
$reportPath = Join-Path -Path $OutputPath -ChildPath "report.$($ReportType.ToLower())"
$reportContent | Set-Content -Path $reportPath -Encoding UTF8

# CrÃ©er un fichier de log
$logPath = Join-Path -Path $OutputPath -ChildPath "report.log"
@"
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: GÃ©nÃ©ration du rapport dÃ©marrÃ©e
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: Fichier d'entrÃ©e : $InputPath
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: Type de rapport : $ReportType
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: Configuration : $ConfigPath
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: Rapport gÃ©nÃ©rÃ© : $reportPath
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: GÃ©nÃ©ration du rapport terminÃ©e
"@ | Set-Content -Path $logPath -Encoding UTF8

Write-Host "Rapport gÃ©nÃ©rÃ© : $reportPath"
Write-Host "Log : $logPath"

exit 0
'@
    Set-Content -Path $reportGeneratorPath -Value $reportGeneratorContent -Encoding UTF8
}

# CrÃ©er un fichier de configuration pour les tests
$tempConfigPath = Join-Path -Path $testDir -ChildPath "reporting-config.json"
@{
    General = @{
        RoadmapPath = "docs\plans\roadmap_complete_2.md"
        ActiveDocumentPath = "docs\plans\plan-modes-stepup.md"
        ReportPath = $reportsDir
    }
    Modes = @{
        Check = @{
            Enabled = $true
            ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "mock-check-mode.ps1"
            Dependencies = @("ReportGenerator")
        }
        Gran = @{
            Enabled = $true
            ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "mock-gran-mode.ps1"
            Dependencies = @("ReportGenerator")
        }
        ReportGenerator = @{
            Enabled = $true
            ScriptPath = $reportGeneratorPath
        }
    }
    Reporting = @{
        Enabled = $true
        DefaultFormat = "HTML"
        OutputPath = $reportsDir
        TemplatesPath = Join-Path -Path $testDir -ChildPath "templates"
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
    [string]$ReportPath
)

Write-Host "Mode CHECK exÃ©cutÃ© avec les paramÃ¨tres suivants :"
Write-Host "FilePath : $FilePath"
Write-Host "TaskIdentifier : $TaskIdentifier"
Write-Host "Force : $Force"
Write-Host "ActiveDocumentPath : $ActiveDocumentPath"
Write-Host "CheckActiveDocument : $CheckActiveDocument"
Write-Host "ConfigPath : $ConfigPath"
Write-Host "ReportPath : $ReportPath"

# CrÃ©er un fichier de sortie pour vÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ©
$outputPath = Join-Path -Path "$PSScriptRoot\temp" -ChildPath "check-mode-output.txt"
@"
FilePath : $FilePath
TaskIdentifier : $TaskIdentifier
Force : $Force
ActiveDocumentPath : $ActiveDocumentPath
CheckActiveDocument : $CheckActiveDocument
ConfigPath : $ConfigPath
ReportPath : $ReportPath
"@ | Set-Content -Path $outputPath -Encoding UTF8

# CrÃ©er un fichier de rÃ©sultats pour le rapport
$resultsPath = Join-Path -Path "$PSScriptRoot\temp" -ChildPath "check-mode-results.json"
@"
{
    "mode": "CHECK",
    "filePath": "$FilePath",
    "taskIdentifier": "$TaskIdentifier",
    "results": [
        {
            "task": "1.2.3",
            "status": "completed",
            "details": "TÃ¢che complÃ©tÃ©e avec succÃ¨s"
        },
        {
            "task": "1.2.4",
            "status": "pending",
            "details": "TÃ¢che en attente"
        },
        {
            "task": "1.2.5",
            "status": "in_progress",
            "details": "TÃ¢che en cours"
        }
    ]
}
"@ | Set-Content -Path $resultsPath -Encoding UTF8

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
    [string]$ReportPath
)

Write-Host "Mode GRAN exÃ©cutÃ© avec les paramÃ¨tres suivants :"
Write-Host "FilePath : $FilePath"
Write-Host "TaskIdentifier : $TaskIdentifier"
Write-Host "Force : $Force"
Write-Host "ConfigPath : $ConfigPath"
Write-Host "ReportPath : $ReportPath"

# CrÃ©er un fichier de sortie pour vÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ©
$outputPath = Join-Path -Path "$PSScriptRoot\temp" -ChildPath "gran-mode-output.txt"
@"
FilePath : $FilePath
TaskIdentifier : $TaskIdentifier
Force : $Force
ConfigPath : $ConfigPath
ReportPath : $ReportPath
"@ | Set-Content -Path $outputPath -Encoding UTF8

# CrÃ©er un fichier de rÃ©sultats pour le rapport
$resultsPath = Join-Path -Path "$PSScriptRoot\temp" -ChildPath "gran-mode-results.json"
@"
{
    "mode": "GRAN",
    "filePath": "$FilePath",
    "taskIdentifier": "$TaskIdentifier",
    "results": [
        {
            "task": "1.2.3",
            "status": "granularized",
            "details": "TÃ¢che granularisÃ©e avec succÃ¨s",
            "subtasks": [
                {
                    "task": "1.2.3.1",
                    "description": "Sous-tÃ¢che 1"
                },
                {
                    "task": "1.2.3.2",
                    "description": "Sous-tÃ¢che 2"
                },
                {
                    "task": "1.2.3.3",
                    "description": "Sous-tÃ¢che 3"
                }
            ]
        }
    ]
}
"@ | Set-Content -Path $resultsPath -Encoding UTF8

exit 0
'@
Set-Content -Path $mockGranModePath -Value $mockGranContent -Encoding UTF8

# CrÃ©er un fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
@"
# Test Roadmap

## TÃ¢che 1.2.3

### Description
Cette tÃ¢che est utilisÃ©e pour les tests d'intÃ©gration avec le gÃ©nÃ©rateur de rapports.

### Sous-tÃ¢ches
- [ ] Sous-tÃ¢che 1
- [ ] Sous-tÃ¢che 2
- [ ] Sous-tÃ¢che 3
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8

# CrÃ©er un rÃ©pertoire pour les modÃ¨les de rapport
$templatesDir = Join-Path -Path $testDir -ChildPath "templates"
if (-not (Test-Path -Path $templatesDir)) {
    New-Item -Path $templatesDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un modÃ¨le de rapport HTML
$htmlTemplatePath = Join-Path -Path $templatesDir -ChildPath "report.html"
@"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>{{title}}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .summary { margin: 20px 0; padding: 10px; background-color: #f5f5f5; border-radius: 5px; }
        .passed { color: green; }
        .failed { color: red; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    <h1>{{title}}</h1>
    <div class="summary">
        <p>Mode : {{mode}}</p>
        <p>Fichier : {{filePath}}</p>
        <p>TÃ¢che : {{taskIdentifier}}</p>
    </div>
    <h2>RÃ©sultats</h2>
    <table>
        <tr>
            <th>TÃ¢che</th>
            <th>Statut</th>
            <th>DÃ©tails</th>
        </tr>
        {{#results}}
        <tr>
            <td>{{task}}</td>
            <td class="{{status}}">{{status}}</td>
            <td>{{details}}</td>
        </tr>
        {{/results}}
    </table>
</body>
</html>
"@ | Set-Content -Path $htmlTemplatePath -Encoding UTF8

# Test 1: IntÃ©gration avec le gÃ©nÃ©rateur de rapports - Mode CHECK
Write-Host "Test 1: IntÃ©gration avec le gÃ©nÃ©rateur de rapports - Mode CHECK" -ForegroundColor Cyan
try {
    # ExÃ©cuter le script avec le mode CHECK
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier que le script a correctement intÃ©grÃ© le gÃ©nÃ©rateur de rapports
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "ReportPath : $([regex]::Escape($reportsDir))") {
            Write-Host "Test 1 rÃ©ussi: Le script a correctement intÃ©grÃ© le gÃ©nÃ©rateur de rapports avec le mode CHECK" -ForegroundColor Green
        } else {
            Write-Host "Test 1 Ã©chouÃ©: Le script n'a pas correctement intÃ©grÃ© le gÃ©nÃ©rateur de rapports avec le mode CHECK" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 1 Ã©chouÃ©: Le fichier de sortie du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }
    
    # VÃ©rifier que le rapport a Ã©tÃ© gÃ©nÃ©rÃ©
    $reportPath = Join-Path -Path $reportsDir -ChildPath "report.html"
    if (Test-Path -Path $reportPath) {
        Write-Host "Test 1 rÃ©ussi: Le rapport a Ã©tÃ© gÃ©nÃ©rÃ©" -ForegroundColor Green
    } else {
        Write-Host "Test 1 Ã©chouÃ©: Le rapport n'a pas Ã©tÃ© gÃ©nÃ©rÃ©" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 1 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec le mode CHECK" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 2: IntÃ©gration avec le gÃ©nÃ©rateur de rapports - Mode GRAN
Write-Host "Test 2: IntÃ©gration avec le gÃ©nÃ©rateur de rapports - Mode GRAN" -ForegroundColor Cyan
try {
    # ExÃ©cuter le script avec le mode GRAN
    $output = & $scriptPath -Mode "GRAN" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier que le script a correctement intÃ©grÃ© le gÃ©nÃ©rateur de rapports
    $granOutputPath = Join-Path -Path $testDir -ChildPath "gran-mode-output.txt"
    if (Test-Path -Path $granOutputPath) {
        $granOutput = Get-Content -Path $granOutputPath -Raw
        if ($granOutput -match "ReportPath : $([regex]::Escape($reportsDir))") {
            Write-Host "Test 2 rÃ©ussi: Le script a correctement intÃ©grÃ© le gÃ©nÃ©rateur de rapports avec le mode GRAN" -ForegroundColor Green
        } else {
            Write-Host "Test 2 Ã©chouÃ©: Le script n'a pas correctement intÃ©grÃ© le gÃ©nÃ©rateur de rapports avec le mode GRAN" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 2 Ã©chouÃ©: Le fichier de sortie du mode GRAN n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }
    
    # VÃ©rifier que le rapport a Ã©tÃ© gÃ©nÃ©rÃ©
    $reportPath = Join-Path -Path $reportsDir -ChildPath "report.html"
    if (Test-Path -Path $reportPath) {
        Write-Host "Test 2 rÃ©ussi: Le rapport a Ã©tÃ© gÃ©nÃ©rÃ©" -ForegroundColor Green
    } else {
        Write-Host "Test 2 Ã©chouÃ©: Le rapport n'a pas Ã©tÃ© gÃ©nÃ©rÃ©" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 2 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec le mode GRAN" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 3: IntÃ©gration avec le gÃ©nÃ©rateur de rapports - Format de rapport personnalisÃ©
Write-Host "Test 3: IntÃ©gration avec le gÃ©nÃ©rateur de rapports - Format de rapport personnalisÃ©" -ForegroundColor Cyan
try {
    # Modifier la configuration pour utiliser un format de rapport personnalisÃ©
    $customConfigPath = Join-Path -Path $testDir -ChildPath "custom-reporting-config.json"
    $config = Get-Content -Path $tempConfigPath -Raw | ConvertFrom-Json
    $config.Reporting.DefaultFormat = "JSON"
    $config | ConvertTo-Json -Depth 5 | Set-Content -Path $customConfigPath -Encoding UTF8
    
    # ExÃ©cuter le script avec le mode CHECK et le format de rapport personnalisÃ©
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $customConfigPath 2>&1
    
    # VÃ©rifier que le rapport a Ã©tÃ© gÃ©nÃ©rÃ© avec le format personnalisÃ©
    $reportPath = Join-Path -Path $reportsDir -ChildPath "report.json"
    if (Test-Path -Path $reportPath) {
        Write-Host "Test 3 rÃ©ussi: Le rapport a Ã©tÃ© gÃ©nÃ©rÃ© avec le format personnalisÃ©" -ForegroundColor Green
    } else {
        Write-Host "Test 3 Ã©chouÃ©: Le rapport n'a pas Ã©tÃ© gÃ©nÃ©rÃ© avec le format personnalisÃ©" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 3 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec le format de rapport personnalisÃ©" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 4: IntÃ©gration avec le gÃ©nÃ©rateur de rapports - Rapport dÃ©sactivÃ©
Write-Host "Test 4: IntÃ©gration avec le gÃ©nÃ©rateur de rapports - Rapport dÃ©sactivÃ©" -ForegroundColor Cyan
try {
    # Modifier la configuration pour dÃ©sactiver les rapports
    $disabledConfigPath = Join-Path -Path $testDir -ChildPath "disabled-reporting-config.json"
    $config = Get-Content -Path $tempConfigPath -Raw | ConvertFrom-Json
    $config.Reporting.Enabled = $false
    $config | ConvertTo-Json -Depth 5 | Set-Content -Path $disabledConfigPath -Encoding UTF8
    
    # Supprimer les rapports existants
    if (Test-Path -Path $reportsDir) {
        Remove-Item -Path $reportsDir -Recurse -Force
        New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null
    }
    
    # ExÃ©cuter le script avec le mode CHECK et les rapports dÃ©sactivÃ©s
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $disabledConfigPath 2>&1
    
    # VÃ©rifier qu'aucun rapport n'a Ã©tÃ© gÃ©nÃ©rÃ©
    $reportPath = Join-Path -Path $reportsDir -ChildPath "report.html"
    if (-not (Test-Path -Path $reportPath)) {
        Write-Host "Test 4 rÃ©ussi: Aucun rapport n'a Ã©tÃ© gÃ©nÃ©rÃ© lorsque les rapports sont dÃ©sactivÃ©s" -ForegroundColor Green
    } else {
        Write-Host "Test 4 Ã©chouÃ©: Un rapport a Ã©tÃ© gÃ©nÃ©rÃ© alors que les rapports sont dÃ©sactivÃ©s" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 4 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec les rapports dÃ©sactivÃ©s" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
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
