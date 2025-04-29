# Tests d'intégration entre le mode manager et le générateur de rapports

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

# Créer un répertoire pour les rapports
$reportsDir = Join-Path -Path $testDir -ChildPath "reports"
if (-not (Test-Path -Path $reportsDir)) {
    New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null
}

# Définir le chemin du générateur de rapports
$reportGeneratorPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\reporting\generate_reports.ps1"
if (-not (Test-Path -Path $reportGeneratorPath)) {
    Write-Warning "Le générateur de rapports est introuvable à l'emplacement : $reportGeneratorPath"
    Write-Warning "Création d'un générateur de rapports simulé pour les tests"
    
    # Créer un générateur de rapports simulé
    $reportGeneratorPath = Join-Path -Path $testDir -ChildPath "generate_reports.ps1"
    $reportGeneratorContent = @'
<#
.SYNOPSIS
    Générateur de rapports simulé pour les tests d'intégration.

.DESCRIPTION
    Ce script simule le générateur de rapports pour les tests d'intégration.

.PARAMETER InputPath
    Chemin du fichier d'entrée pour le rapport.

.PARAMETER OutputPath
    Chemin du répertoire de sortie pour le rapport.

.PARAMETER ReportType
    Type de rapport à générer.

.PARAMETER ConfigPath
    Chemin du fichier de configuration.

.EXAMPLE
    .\generate_reports.ps1 -InputPath "input.json" -OutputPath "reports" -ReportType "HTML" -ConfigPath "config.json"

.NOTES
    Ce script est utilisé pour les tests d'intégration du mode manager.
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

# Vérifier que le fichier d'entrée existe
if (-not (Test-Path -Path $InputPath)) {
    Write-Error "Le fichier d'entrée est introuvable à l'emplacement : $InputPath"
    exit 1
}

# Vérifier que le répertoire de sortie existe
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Simuler la génération d'un rapport
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
        <p>Fichier d'entrée : $InputPath</p>
        <p>Type de rapport : $ReportType</p>
        <p>Configuration : $ConfigPath</p>
    </div>
    <h2>Détails</h2>
    <table>
        <tr>
            <th>Élément</th>
            <th>Statut</th>
        </tr>
        <tr>
            <td>Élément 1</td>
            <td class="passed">Réussi</td>
        </tr>
        <tr>
            <td>Élément 2</td>
            <td class="passed">Réussi</td>
        </tr>
        <tr>
            <td>Élément 3</td>
            <td class="passed">Réussi</td>
        </tr>
    </table>
</body>
</html>
"@

# Générer le rapport
$reportPath = Join-Path -Path $OutputPath -ChildPath "report.$($ReportType.ToLower())"
$reportContent | Set-Content -Path $reportPath -Encoding UTF8

# Créer un fichier de log
$logPath = Join-Path -Path $OutputPath -ChildPath "report.log"
@"
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: Génération du rapport démarrée
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: Fichier d'entrée : $InputPath
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: Type de rapport : $ReportType
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: Configuration : $ConfigPath
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: Rapport généré : $reportPath
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: Génération du rapport terminée
"@ | Set-Content -Path $logPath -Encoding UTF8

Write-Host "Rapport généré : $reportPath"
Write-Host "Log : $logPath"

exit 0
'@
    Set-Content -Path $reportGeneratorPath -Value $reportGeneratorContent -Encoding UTF8
}

# Créer un fichier de configuration pour les tests
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
    [string]$ReportPath
)

Write-Host "Mode CHECK exécuté avec les paramètres suivants :"
Write-Host "FilePath : $FilePath"
Write-Host "TaskIdentifier : $TaskIdentifier"
Write-Host "Force : $Force"
Write-Host "ActiveDocumentPath : $ActiveDocumentPath"
Write-Host "CheckActiveDocument : $CheckActiveDocument"
Write-Host "ConfigPath : $ConfigPath"
Write-Host "ReportPath : $ReportPath"

# Créer un fichier de sortie pour vérifier que le script a été exécuté
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

# Créer un fichier de résultats pour le rapport
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
            "details": "Tâche complétée avec succès"
        },
        {
            "task": "1.2.4",
            "status": "pending",
            "details": "Tâche en attente"
        },
        {
            "task": "1.2.5",
            "status": "in_progress",
            "details": "Tâche en cours"
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

Write-Host "Mode GRAN exécuté avec les paramètres suivants :"
Write-Host "FilePath : $FilePath"
Write-Host "TaskIdentifier : $TaskIdentifier"
Write-Host "Force : $Force"
Write-Host "ConfigPath : $ConfigPath"
Write-Host "ReportPath : $ReportPath"

# Créer un fichier de sortie pour vérifier que le script a été exécuté
$outputPath = Join-Path -Path "$PSScriptRoot\temp" -ChildPath "gran-mode-output.txt"
@"
FilePath : $FilePath
TaskIdentifier : $TaskIdentifier
Force : $Force
ConfigPath : $ConfigPath
ReportPath : $ReportPath
"@ | Set-Content -Path $outputPath -Encoding UTF8

# Créer un fichier de résultats pour le rapport
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
            "details": "Tâche granularisée avec succès",
            "subtasks": [
                {
                    "task": "1.2.3.1",
                    "description": "Sous-tâche 1"
                },
                {
                    "task": "1.2.3.2",
                    "description": "Sous-tâche 2"
                },
                {
                    "task": "1.2.3.3",
                    "description": "Sous-tâche 3"
                }
            ]
        }
    ]
}
"@ | Set-Content -Path $resultsPath -Encoding UTF8

exit 0
'@
Set-Content -Path $mockGranModePath -Value $mockGranContent -Encoding UTF8

# Créer un fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
@"
# Test Roadmap

## Tâche 1.2.3

### Description
Cette tâche est utilisée pour les tests d'intégration avec le générateur de rapports.

### Sous-tâches
- [ ] Sous-tâche 1
- [ ] Sous-tâche 2
- [ ] Sous-tâche 3
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8

# Créer un répertoire pour les modèles de rapport
$templatesDir = Join-Path -Path $testDir -ChildPath "templates"
if (-not (Test-Path -Path $templatesDir)) {
    New-Item -Path $templatesDir -ItemType Directory -Force | Out-Null
}

# Créer un modèle de rapport HTML
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
        <p>Tâche : {{taskIdentifier}}</p>
    </div>
    <h2>Résultats</h2>
    <table>
        <tr>
            <th>Tâche</th>
            <th>Statut</th>
            <th>Détails</th>
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

# Test 1: Intégration avec le générateur de rapports - Mode CHECK
Write-Host "Test 1: Intégration avec le générateur de rapports - Mode CHECK" -ForegroundColor Cyan
try {
    # Exécuter le script avec le mode CHECK
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier que le script a correctement intégré le générateur de rapports
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "ReportPath : $([regex]::Escape($reportsDir))") {
            Write-Host "Test 1 réussi: Le script a correctement intégré le générateur de rapports avec le mode CHECK" -ForegroundColor Green
        } else {
            Write-Host "Test 1 échoué: Le script n'a pas correctement intégré le générateur de rapports avec le mode CHECK" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 1 échoué: Le fichier de sortie du mode CHECK n'a pas été créé" -ForegroundColor Red
    }
    
    # Vérifier que le rapport a été généré
    $reportPath = Join-Path -Path $reportsDir -ChildPath "report.html"
    if (Test-Path -Path $reportPath) {
        Write-Host "Test 1 réussi: Le rapport a été généré" -ForegroundColor Green
    } else {
        Write-Host "Test 1 échoué: Le rapport n'a pas été généré" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 1 échoué: Une erreur s'est produite lors de l'exécution du script avec le mode CHECK" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 2: Intégration avec le générateur de rapports - Mode GRAN
Write-Host "Test 2: Intégration avec le générateur de rapports - Mode GRAN" -ForegroundColor Cyan
try {
    # Exécuter le script avec le mode GRAN
    $output = & $scriptPath -Mode "GRAN" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier que le script a correctement intégré le générateur de rapports
    $granOutputPath = Join-Path -Path $testDir -ChildPath "gran-mode-output.txt"
    if (Test-Path -Path $granOutputPath) {
        $granOutput = Get-Content -Path $granOutputPath -Raw
        if ($granOutput -match "ReportPath : $([regex]::Escape($reportsDir))") {
            Write-Host "Test 2 réussi: Le script a correctement intégré le générateur de rapports avec le mode GRAN" -ForegroundColor Green
        } else {
            Write-Host "Test 2 échoué: Le script n'a pas correctement intégré le générateur de rapports avec le mode GRAN" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 2 échoué: Le fichier de sortie du mode GRAN n'a pas été créé" -ForegroundColor Red
    }
    
    # Vérifier que le rapport a été généré
    $reportPath = Join-Path -Path $reportsDir -ChildPath "report.html"
    if (Test-Path -Path $reportPath) {
        Write-Host "Test 2 réussi: Le rapport a été généré" -ForegroundColor Green
    } else {
        Write-Host "Test 2 échoué: Le rapport n'a pas été généré" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 2 échoué: Une erreur s'est produite lors de l'exécution du script avec le mode GRAN" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 3: Intégration avec le générateur de rapports - Format de rapport personnalisé
Write-Host "Test 3: Intégration avec le générateur de rapports - Format de rapport personnalisé" -ForegroundColor Cyan
try {
    # Modifier la configuration pour utiliser un format de rapport personnalisé
    $customConfigPath = Join-Path -Path $testDir -ChildPath "custom-reporting-config.json"
    $config = Get-Content -Path $tempConfigPath -Raw | ConvertFrom-Json
    $config.Reporting.DefaultFormat = "JSON"
    $config | ConvertTo-Json -Depth 5 | Set-Content -Path $customConfigPath -Encoding UTF8
    
    # Exécuter le script avec le mode CHECK et le format de rapport personnalisé
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $customConfigPath 2>&1
    
    # Vérifier que le rapport a été généré avec le format personnalisé
    $reportPath = Join-Path -Path $reportsDir -ChildPath "report.json"
    if (Test-Path -Path $reportPath) {
        Write-Host "Test 3 réussi: Le rapport a été généré avec le format personnalisé" -ForegroundColor Green
    } else {
        Write-Host "Test 3 échoué: Le rapport n'a pas été généré avec le format personnalisé" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 3 échoué: Une erreur s'est produite lors de l'exécution du script avec le format de rapport personnalisé" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 4: Intégration avec le générateur de rapports - Rapport désactivé
Write-Host "Test 4: Intégration avec le générateur de rapports - Rapport désactivé" -ForegroundColor Cyan
try {
    # Modifier la configuration pour désactiver les rapports
    $disabledConfigPath = Join-Path -Path $testDir -ChildPath "disabled-reporting-config.json"
    $config = Get-Content -Path $tempConfigPath -Raw | ConvertFrom-Json
    $config.Reporting.Enabled = $false
    $config | ConvertTo-Json -Depth 5 | Set-Content -Path $disabledConfigPath -Encoding UTF8
    
    # Supprimer les rapports existants
    if (Test-Path -Path $reportsDir) {
        Remove-Item -Path $reportsDir -Recurse -Force
        New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null
    }
    
    # Exécuter le script avec le mode CHECK et les rapports désactivés
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $disabledConfigPath 2>&1
    
    # Vérifier qu'aucun rapport n'a été généré
    $reportPath = Join-Path -Path $reportsDir -ChildPath "report.html"
    if (-not (Test-Path -Path $reportPath)) {
        Write-Host "Test 4 réussi: Aucun rapport n'a été généré lorsque les rapports sont désactivés" -ForegroundColor Green
    } else {
        Write-Host "Test 4 échoué: Un rapport a été généré alors que les rapports sont désactivés" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 4 échoué: Une erreur s'est produite lors de l'exécution du script avec les rapports désactivés" -ForegroundColor Red
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

Write-Host "Tests terminés." -ForegroundColor Cyan
